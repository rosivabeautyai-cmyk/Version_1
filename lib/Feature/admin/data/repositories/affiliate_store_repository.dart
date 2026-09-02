import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:rosivia/core/network/app_config.dart';

import '../models/activity_log_entry.dart';
import '../models/affiliate_store_model.dart';
import '../models/affiliate_sync_log_model.dart';
import 'admin_repository.dart';

/// Result of a "Test Connection" call.
class AffiliateTestResult {
  final bool ok;
  final int? productsDetected;
  final int sampleCount;
  final List<Map<String, dynamic>> sample;
  final String? errorCode;
  final String? errorMessage;

  const AffiliateTestResult({
    required this.ok,
    this.productsDetected,
    this.sampleCount = 0,
    this.sample = const [],
    this.errorCode,
    this.errorMessage,
  });

  factory AffiliateTestResult.fromJson(Map<String, dynamic> j) {
    final err = j['error'];
    return AffiliateTestResult(
      ok: j['ok'] == true,
      productsDetected: (j['productsDetected'] as num?)?.toInt(),
      sampleCount: (j['sampleCount'] as num?)?.toInt() ?? 0,
      sample: (j['sample'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
      errorCode: err is Map ? err['code'] as String? : null,
      errorMessage: err is Map ? err['userMessage'] as String? : null,
    );
  }

  factory AffiliateTestResult.localError(String message) =>
      AffiliateTestResult(ok: false, errorMessage: message, errorCode: 'client');
}

/// Result of a "Sync Now" call.
class AffiliateSyncTriggerResult {
  /// 'inline' (ran now, [log] populated) or 'queued' (job enqueued).
  final String mode;
  final String? jobId;
  final AffiliateSyncLog? log;
  final String? message;
  final bool ok;

  const AffiliateSyncTriggerResult({
    required this.mode,
    required this.ok,
    this.jobId,
    this.log,
    this.message,
  });
}

/// Every affiliate-store Firestore read/write + the two secure backend
/// calls (Test Connection / Sync Now).
///
/// Firestore writes here only ever touch the PUBLIC store config that
/// `firestore.rules` lets an admin write. Private feed passwords / API
/// keys are never sent here — they live only in the backend environment.
class AffiliateStoreRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final http.Client _http;
  final AdminRepository _admin;
  final String _backendBaseUrl;

  AffiliateStoreRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
    AdminRepository? adminRepository,
    String? backendBaseUrl,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _http = httpClient ?? http.Client(),
        _admin = adminRepository ?? AdminRepository(),
        _backendBaseUrl =
            (backendBaseUrl ?? AppConfig.aiBackendBaseUrl).replaceAll(
          RegExp(r'/+$'),
          '',
        );

  CollectionReference<Map<String, dynamic>> get _stores =>
      _db.collection('affiliateStores');
  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('affiliateSyncLogs');

  bool get backendConfigured => _backendBaseUrl.isNotEmpty;

  // ------------------------------------------------------------------
  // Firestore CRUD
  // ------------------------------------------------------------------

  Stream<List<AffiliateStore>> watchStores() {
    return _stores.snapshots().map(
          (snap) => snap.docs.map(AffiliateStore.fromDoc).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        );
  }

  Future<List<AffiliateStore>> loadStores() async {
    final snap = await _stores.get();
    return snap.docs.map(AffiliateStore.fromDoc).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<AffiliateStore?> getStore(String id) async {
    final doc = await _stores.doc(id).get();
    return doc.exists ? AffiliateStore.fromDoc(doc) : null;
  }

  /// Creates a store. The document id is the slug (kebab-case, unique).
  Future<String> createStore(AffiliateStore store) async {
    final slug = _slugify(store.slug.isNotEmpty ? store.slug : store.name);
    final ref = _stores.doc(slug);
    if ((await ref.get()).exists) {
      throw StateError('A store with the id "$slug" already exists.');
    }
    await ref.set({
      ...store.toWriteMap(),
      'slug': slug,
      'syncStatus': 'idle',
      'productCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _admin.logActivity(
      action: ActivityAction.affiliateStoreCreated,
      entityType: 'affiliateStore',
      entityId: slug,
      summary: 'Created affiliate store "${store.name}" (${store.integrationType.value})',
    );
    return slug;
  }

  Future<void> updateStore(String id, AffiliateStore store) async {
    final data = store.toWriteMap()..['updatedAt'] = FieldValue.serverTimestamp();
    await _stores.doc(id).set(data, SetOptions(merge: true));
    await _admin.logActivity(
      action: ActivityAction.affiliateStoreUpdated,
      entityType: 'affiliateStore',
      entityId: id,
      summary: 'Updated affiliate store "${store.name}"',
    );
  }

  Future<void> setStoreEnabled(String id, bool enabled) async {
    await _stores.doc(id).set({
      'status': enabled ? 'active' : 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _admin.logActivity(
      action: enabled
          ? ActivityAction.affiliateStoreEnabled
          : ActivityAction.affiliateStoreDisabled,
      entityType: 'affiliateStore',
      entityId: id,
      summary: 'Store $id ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Deletes the store document. Its imported products are NOT hard
  /// deleted — the next scheduled sync (or a manual pass) leaves them,
  /// but with no active store they simply stop refreshing. Admins can
  /// deactivate them from the Products screen.
  Future<void> deleteStore(String id) async {
    await _stores.doc(id).delete();
    await _admin.logActivity(
      action: ActivityAction.affiliateStoreDeleted,
      entityType: 'affiliateStore',
      entityId: id,
      summary: 'Deleted affiliate store $id',
    );
  }

  // ------------------------------------------------------------------
  // Sync history
  // ------------------------------------------------------------------

  Stream<List<AffiliateSyncLog>> watchSyncLogs(String storeId, {int limit = 30}) {
    return _logs
        .where('storeId', isEqualTo: storeId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AffiliateSyncLog.fromDoc).toList());
  }

  Future<List<AffiliateSyncLog>> loadRecentLogs({int limit = 20}) async {
    final snap =
        await _logs.orderBy('startedAt', descending: true).limit(limit).get();
    return snap.docs.map(AffiliateSyncLog.fromDoc).toList();
  }

  // ------------------------------------------------------------------
  // Secure backend calls
  // ------------------------------------------------------------------

  Future<String?> _idToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  Future<AffiliateTestResult> testConnection(
    String storeId, {
    Map<String, dynamic>? storeOverride,
  }) async {
    if (!backendConfigured) {
      return AffiliateTestResult.localError(
        'The backend URL is not configured for this build.',
      );
    }
    final token = await _idToken();
    if (token == null) {
      return AffiliateTestResult.localError('Not signed in.');
    }
    try {
      final res = await _http
          .post(
            Uri.parse(
              '$_backendBaseUrl/api/admin/affiliate-stores/$storeId/test-connection',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'storeOverride': ?storeOverride}),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 401 || res.statusCode == 403) {
        return AffiliateTestResult.localError('Admin authorization failed.');
      }
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) {
        return AffiliateTestResult.fromJson(body);
      }
      return AffiliateTestResult.localError('Unexpected response from the backend.');
    } on TimeoutException {
      return AffiliateTestResult.localError('The test timed out.');
    } catch (e) {
      return AffiliateTestResult.localError('Could not reach the backend.');
    }
  }

  /// Triggers a sync. [mode] is 'auto' (backend decides inline vs queue),
  /// 'inline' or 'queue'.
  Future<AffiliateSyncTriggerResult> syncNow(
    String storeId, {
    String mode = 'auto',
  }) async {
    if (!backendConfigured) {
      return const AffiliateSyncTriggerResult(
        mode: 'error',
        ok: false,
        message: 'The backend URL is not configured for this build.',
      );
    }
    final token = await _idToken();
    if (token == null) {
      return const AffiliateSyncTriggerResult(
        mode: 'error',
        ok: false,
        message: 'Not signed in.',
      );
    }
    await _admin.logActivity(
      action: ActivityAction.affiliateSyncTriggered,
      entityType: 'affiliateStore',
      entityId: storeId,
      summary: 'Manual sync requested for $storeId',
    );
    try {
      final res = await _http
          .post(
            Uri.parse(
              '$_backendBaseUrl/api/admin/affiliate-stores/$storeId/sync',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'mode': mode}),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 401 || res.statusCode == 403) {
        return const AffiliateSyncTriggerResult(
          mode: 'error',
          ok: false,
          message: 'Admin authorization failed.',
        );
      }
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) {
        return const AffiliateSyncTriggerResult(
          mode: 'error',
          ok: false,
          message: 'Unexpected response from the backend.',
        );
      }
      if (body['mode'] == 'queued') {
        return AffiliateSyncTriggerResult(
          mode: 'queued',
          ok: true,
          jobId: body['jobId'] as String?,
          message: body['message'] as String?,
        );
      }
      if (body['mode'] == 'inline' && body['log'] is Map) {
        final l = (body['log'] as Map).cast<String, dynamic>();
        return AffiliateSyncTriggerResult(
          mode: 'inline',
          ok: l['status'] != 'error',
          message: l['errorSummary'] as String?,
          log: _logFromInline(l),
        );
      }
      return AffiliateSyncTriggerResult(
        mode: 'error',
        ok: false,
        message: body['message'] as String? ?? 'Sync failed.',
      );
    } on TimeoutException {
      return const AffiliateSyncTriggerResult(
        mode: 'error',
        ok: false,
        message: 'The sync request timed out. Check Sync History shortly.',
      );
    } catch (e) {
      return const AffiliateSyncTriggerResult(
        mode: 'error',
        ok: false,
        message: 'Could not reach the backend.',
      );
    }
  }

  AffiliateSyncLog _logFromInline(Map<String, dynamic> l) => AffiliateSyncLog(
        id: l['id'] as String? ?? 'inline',
        storeId: l['storeId'] as String? ?? '',
        startedAt: DateTime.tryParse(l['startedAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(l['completedAt'] as String? ?? ''),
        statusValue: l['status'] as String? ?? 'success',
        triggeredBy: l['triggeredBy'] as String? ?? 'admin',
        totalFetched: (l['totalFetched'] as num?)?.toInt() ?? 0,
        newProducts: (l['newProducts'] as num?)?.toInt() ?? 0,
        updatedProducts: (l['updatedProducts'] as num?)?.toInt() ?? 0,
        deactivatedProducts: (l['deactivatedProducts'] as num?)?.toInt() ?? 0,
        failedProducts: (l['failedProducts'] as num?)?.toInt() ?? 0,
        errorSummary: l['errorSummary'] as String? ?? '',
        errorCode: l['errorCode'] as String?,
      );

  static String _slugify(String input) {
    final s = input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'store-${DateTime.now().millisecondsSinceEpoch}' : s;
  }

  static String slugify(String input) => _slugify(input);

  void dispose() => _http.close();
}
