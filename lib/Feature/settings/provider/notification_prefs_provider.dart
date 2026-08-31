import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosivia/core/services/notification_service.dart';

/// Notification settings state.
///
/// * The three category switches (AI recs / price drops / new
///   discoveries) are on-device delivery *preferences* the backend
///   would honour when sending.
/// * [pushStatus] / [enablePush] / [disablePush] are the real
///   device-level Firebase Cloud Messaging control — permission +
///   token registration via [NotificationService].
class NotificationPrefsProvider extends ChangeNotifier {
  static const _aiRecsKey = 'notif_ai_recommendations';
  static const _priceDropsKey = 'notif_price_drops';
  static const _newDiscoveriesKey = 'notif_new_discoveries';

  bool _aiRecommendations = true;
  bool _priceDrops = true;
  bool _newDiscoveries = false;

  PushStatus _pushStatus = PushStatus.unknown;
  bool _pushBusy = false;

  bool get aiRecommendations => _aiRecommendations;
  bool get priceDrops => _priceDrops;
  bool get newDiscoveries => _newDiscoveries;

  PushStatus get pushStatus => _pushStatus;
  bool get pushBusy => _pushBusy;
  bool get pushOn => _pushStatus == PushStatus.enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aiRecommendations = prefs.getBool(_aiRecsKey) ?? true;
    _priceDrops = prefs.getBool(_priceDropsKey) ?? true;
    _newDiscoveries = prefs.getBool(_newDiscoveriesKey) ?? false;
    notifyListeners();
    // Best-effort — never blocks the settings screen from rendering.
    unawaited(refreshPushStatus());
  }

  Future<void> refreshPushStatus() async {
    try {
      _pushStatus = await NotificationService.instance.status();
      notifyListeners();
    } catch (_) {
      // leave as-is
    }
  }

  /// Turn device push on. Returns the outcome so the UI can show the
  /// right message (granted / denied / not-configured / retryable).
  Future<PushEnableResult> enablePush(String uid) async {
    _pushBusy = true;
    notifyListeners();
    try {
      final res = await NotificationService.instance.enable(uid);
      await refreshPushStatus();
      return res;
    } finally {
      _pushBusy = false;
      notifyListeners();
    }
  }

  Future<void> disablePush(String uid) async {
    _pushBusy = true;
    notifyListeners();
    try {
      await NotificationService.instance.disable(uid);
      await refreshPushStatus();
    } finally {
      _pushBusy = false;
      notifyListeners();
    }
  }

  Future<void> setAiRecommendations(bool value) async {
    _aiRecommendations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiRecsKey, value);
  }

  Future<void> setPriceDrops(bool value) async {
    _priceDrops = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_priceDropsKey, value);
  }

  Future<void> setNewDiscoveries(bool value) async {
    _newDiscoveries = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newDiscoveriesKey, value);
  }
}
