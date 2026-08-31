import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of asking to turn notifications on.
enum PushEnableResult {
  /// Permission granted and (where possible) a token was stored.
  enabled,

  /// The user (or the OS/browser) refused. Do NOT ask again automatically.
  denied,

  /// Web build without an FCM Web-Push VAPID key configured — nothing to
  /// enable. (`--dart-define=FCM_VAPID_KEY=...`)
  notConfigured,

  /// Something went wrong (offline, plugin error). Safe to retry later.
  error,
}

/// Current push-notification state, for the Settings UI.
enum PushStatus { unknown, notConfigured, denied, notEnabled, enabled }

/// Platform-safe wrapper around Firebase Cloud Messaging.
///
/// * **Android / Web** are fully wired here.
/// * **iOS** shares this code but needs an APNs auth key uploaded to
///   Firebase and the Push Notifications capability added in Xcode
///   before `getToken()` returns anything — until then `enable()`
///   degrades to [PushEnableResult.error] on iOS without crashing.
///
/// It never requests permission on its own — [initListeners] only wires
/// up message handlers; the OS/browser prompt happens only when the user
/// flips the Settings toggle ([enable]).
///
/// No `dart:io`. No secrets: the Web-Push VAPID key is a *public* client
/// key read from `--dart-define`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Set as `MaterialApp.navigatorKey` so a notification tap can route.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Public Web-Push key. Empty on native and on web builds that didn't
  /// pass `--dart-define=FCM_VAPID_KEY=...`.
  static const String _vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  static const _deviceIdKey = 'fcm_device_id_v1';
  static const _enabledKey = 'push_enabled_v1';

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _listenersReady = false;

  bool get webPushConfigured => !kIsWeb || _vapidKey.isNotEmpty;

  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  // ---------------------------------------------------------------------
  // Startup — handlers only, NO permission prompt.
  // ---------------------------------------------------------------------
  Future<void> initListeners() async {
    if (_listenersReady) return;
    _listenersReady = true;
    try {
      FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
        onError: (Object e) => debugPrint('onMessage error: $e'),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        _openFromMessage,
        onError: (Object e) => debugPrint('onMessageOpenedApp error: $e'),
      );
      _fm.onTokenRefresh.listen(
        (token) async {
          final uid = await _lastUid();
          if (uid != null && await isEnabledLocally()) {
            await _storeToken(uid, token);
          }
        },
        onError: (Object e) => debugPrint('onTokenRefresh error: $e'),
      );
      final initial = await _fm.getInitialMessage();
      if (initial != null) _openFromMessage(initial);
    } catch (e) {
      debugPrint('NotificationService.initListeners: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------
  Future<bool> isEnabledLocally() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<PushStatus> status() async {
    if (!webPushConfigured) return PushStatus.notConfigured;
    try {
      final settings = await _fm.getNotificationSettings();
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return (await isEnabledLocally())
              ? PushStatus.enabled
              : PushStatus.notEnabled;
        case AuthorizationStatus.notDetermined:
          return PushStatus.notEnabled;
        default:
          // denied / deniedPermanently / anything future
          return PushStatus.denied;
      }
    } catch (e) {
      debugPrint('NotificationService.status: $e');
      return PushStatus.unknown;
    }
  }

  // ---------------------------------------------------------------------
  // Enable / disable (driven by the Settings toggle only)
  // ---------------------------------------------------------------------
  Future<PushEnableResult> enable(String uid) async {
    if (!webPushConfigured) return PushEnableResult.notConfigured;
    try {
      final settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final ok =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!ok) return PushEnableResult.denied;

      final token = await _currentToken();
      if (token == null) {
        // e.g. iOS without APNs configured yet.
        return PushEnableResult.error;
      }
      await _storeToken(uid, token);
      await _setEnabledLocally(true);
      await _rememberUid(uid);
      return PushEnableResult.enabled;
    } catch (e) {
      debugPrint('NotificationService.enable: $e');
      return PushEnableResult.error;
    }
  }

  Future<void> disable(String uid) async {
    await _setEnabledLocally(false);
    try {
      final deviceId = await _deviceId();
      await _db.collection('users').doc(uid).set({
        'devices': {deviceId: FieldValue.delete()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NotificationService.disable(firestore): $e');
    }
    try {
      await _fm.deleteToken();
    } catch (e) {
      debugPrint('NotificationService.disable(deleteToken): $e');
    }
  }

  /// Called right after a successful sign-in and on app resume: if the
  /// user previously enabled push and still has permission, make sure
  /// this device's token is current under their uid.
  Future<void> syncOnLogin(String uid) async {
    try {
      if (!await isEnabledLocally()) {
        await _rememberUid(uid);
        return;
      }
      final st = await status();
      if (st != PushStatus.enabled) return;
      final token = await _currentToken();
      if (token != null) await _storeToken(uid, token);
      await _rememberUid(uid);
    } catch (e) {
      debugPrint('NotificationService.syncOnLogin: $e');
    }
  }

  /// Best-effort cleanup so a signed-out device stops receiving that
  /// account's notifications. Keeps the local "enabled" flag so the user
  /// doesn't have to re-grant OS permission next time they sign in.
  Future<void> onLogout(String? uid) async {
    if (uid == null) return;
    try {
      final deviceId = await _deviceId();
      await _db.collection('users').doc(uid).set({
        'devices': {deviceId: FieldValue.delete()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('NotificationService.onLogout: $e');
    }
  }

  // ---------------------------------------------------------------------
  // internals
  // ---------------------------------------------------------------------
  Future<String?> _currentToken() async {
    try {
      if (kIsWeb) {
        if (_vapidKey.isEmpty) return null;
        return _fm.getToken(vapidKey: _vapidKey);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // No APNs token => FCM token would be null / throw. Bail quietly.
        final apns = await _fm.getAPNSToken();
        if (apns == null) return null;
      }
      return _fm.getToken();
    } catch (e) {
      debugPrint('NotificationService._currentToken: $e');
      return null;
    }
  }

  Future<void> _storeToken(String uid, String token) async {
    final deviceId = await _deviceId();
    await _db.collection('users').doc(uid).set({
      'devices': {
        deviceId: {
          'token': token,
          'platform': _platform,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
    }, SetOptions(merge: true));
  }

  void _onForegroundMessage(RemoteMessage message) {
    // A system tray notification while the app is foregrounded needs
    // flutter_local_notifications; deliberately not adding that dependency
    // now. Surface it in-app instead via the navigator's context.
    final n = message.notification;
    final ctx = navigatorKey.currentContext;
    if (n == null || ctx == null) return;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          [n.title, n.body].whereType<String>().join(' — '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _openFromMessage(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route);
    }
  }

  Future<String> _deviceId() async {
    final p = await SharedPreferences.getInstance();
    var id = p.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      final r = Random.secure();
      id = List.generate(
        16,
        (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await p.setString(_deviceIdKey, id);
    }
    return id;
  }

  Future<void> _setEnabledLocally(bool value) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_enabledKey, value);
    } catch (_) {}
  }

  Future<void> _rememberUid(String uid) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('push_last_uid_v1', uid);
    } catch (_) {}
  }

  Future<String?> _lastUid() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getString('push_last_uid_v1');
    } catch (_) {
      return null;
    }
  }
}
