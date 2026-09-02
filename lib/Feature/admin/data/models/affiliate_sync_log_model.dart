import 'package:cloud_firestore/cloud_firestore.dart';

/// One row in `affiliateSyncLogs` — the history of a single sync run for
/// a store. Written by the backend sync engine
/// (scripts/affiliate-sync/syncEngine.mjs); read-only for the Admin UI.
class AffiliateSyncLog {
  final String id;
  final String storeId;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// success | partial | error
  final String statusValue;
  final String triggeredBy; // admin | scheduled | system

  final int totalFetched;
  final int newProducts;
  final int updatedProducts;
  final int deactivatedProducts;
  final int failedProducts;

  final String errorSummary;
  final String? errorCode;

  /// Why the deactivation sweep was skipped, if it was:
  /// `empty_feed` (0 products from the source — run failed) or
  /// `catalog_drop` (>80% fewer active products — run flagged). Null
  /// when the sweep ran normally.
  final String? sweepSkipped;

  final int seenCount;
  final int existingActiveCount;

  /// Up to ~10 { code, detail } entries for skipped products.
  final List<Map<String, dynamic>> failureSamples;

  const AffiliateSyncLog({
    required this.id,
    required this.storeId,
    this.startedAt,
    this.completedAt,
    this.statusValue = 'success',
    this.triggeredBy = 'system',
    this.totalFetched = 0,
    this.newProducts = 0,
    this.updatedProducts = 0,
    this.deactivatedProducts = 0,
    this.failedProducts = 0,
    this.errorSummary = '',
    this.errorCode,
    this.sweepSkipped,
    this.seenCount = 0,
    this.existingActiveCount = 0,
    this.failureSamples = const [],
  });

  bool get isError => statusValue == 'error';
  bool get isPartial => statusValue == 'partial';
  bool get isSuccess => statusValue == 'success';
  bool get isNeedsReview => statusValue == 'needs_review';

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  factory AffiliateSyncLog.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      AffiliateSyncLog.fromJson(doc.id, doc.data() ?? const <String, dynamic>{});

  factory AffiliateSyncLog.fromJson(String id, Map<String, dynamic> d) {
    final samples = d['failureSamples'];
    return AffiliateSyncLog(
      id: id,
      storeId: d['storeId'] as String? ?? '',
      startedAt: _date(d['startedAt']),
      completedAt: _date(d['completedAt']),
      statusValue: d['status'] as String? ?? 'success',
      triggeredBy: d['triggeredBy'] as String? ?? 'system',
      totalFetched: (d['totalFetched'] as num?)?.toInt() ?? 0,
      newProducts: (d['newProducts'] as num?)?.toInt() ?? 0,
      updatedProducts: (d['updatedProducts'] as num?)?.toInt() ?? 0,
      deactivatedProducts: (d['deactivatedProducts'] as num?)?.toInt() ?? 0,
      failedProducts: (d['failedProducts'] as num?)?.toInt() ?? 0,
      errorSummary: d['errorSummary'] as String? ?? '',
      errorCode: d['errorCode'] as String?,
      sweepSkipped: d['sweepSkipped'] as String?,
      seenCount: (d['seenCount'] as num?)?.toInt() ?? 0,
      existingActiveCount: (d['existingActiveCount'] as num?)?.toInt() ?? 0,
      failureSamples: samples is List
          ? samples
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList()
          : const [],
    );
  }
}
