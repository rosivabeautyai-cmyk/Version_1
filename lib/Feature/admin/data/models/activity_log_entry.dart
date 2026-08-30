import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry in the admin audit trail (`activity_log` collection).
///
/// Written client-side by an admin, but `firestore.rules` pins
/// `actorUid == request.auth.uid` and `createdAt == request.time`, so
/// an admin can only ever log an action AS themselves, at server time —
/// no forging another actor, no back-dating, no editing/deleting.
/// Never carries secrets (keys, passwords, service accounts).
class ActivityLogEntry {
  final String id;
  final String actorUid;
  final String action;
  final String entityType;
  final String? entityId;
  final String summary;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const ActivityLogEntry({
    required this.id,
    required this.actorUid,
    required this.action,
    required this.entityType,
    this.entityId,
    this.summary = '',
    this.metadata = const {},
    this.createdAt,
  });

  factory ActivityLogEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ActivityLogEntry(
      id: doc.id,
      actorUid: d['actorUid'] as String? ?? '',
      action: d['action'] as String? ?? 'unknown',
      entityType: d['entityType'] as String? ?? '',
      entityId: d['entityId'] as String?,
      summary: d['summary'] as String? ?? '',
      metadata: (d['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Canonical action strings (keep in sync with the report / tests).
abstract class ActivityAction {
  static const productCreated = 'product_created';
  static const productUpdated = 'product_updated';
  static const productDeactivated = 'product_deactivated';
  static const productReactivated = 'product_reactivated';
  static const countryOffersChanged = 'country_offers_changed';
  static const userDisabled = 'user_disabled';
  static const userEnabled = 'user_enabled';
  static const countryConfigChanged = 'country_config_changed';
  static const currencyConfigChanged = 'currency_config_changed';
  static const aiConfigChanged = 'ai_config_changed';
}
