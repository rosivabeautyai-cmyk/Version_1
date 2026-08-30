import 'package:cloud_firestore/cloud_firestore.dart';

/// `app_config/ai` — the admin-controlled switches for the ROSIVA AI
/// assistant.
///
/// The ROSIVA AI **backend** is the authority: it reads this same
/// document with the Admin SDK and refuses requests when `enabled`
/// is false or `maintenanceMode` is true. The Flutter client reads it
/// only to show a friendlier banner / disable the input instead of a
/// generic error — it is never the enforcement point.
class AiConfig {
  final bool enabled;
  final bool maintenanceMode;
  final String maintenanceMessageEn;
  final String maintenanceMessageAr;

  /// Max AI chat requests per calendar day (UTC), all users combined.
  /// `null` = unlimited. Enforced by the backend, never the client.
  final int? dailyGlobalLimit;

  /// Max AI chat requests per calendar day per user (advisory user id
  /// from the request). `null` = unlimited. Backend-enforced.
  final int? dailyUserLimit;

  final DateTime? updatedAt;
  final String? updatedBy;

  const AiConfig({
    this.enabled = true,
    this.maintenanceMode = false,
    this.maintenanceMessageEn = '',
    this.maintenanceMessageAr = '',
    this.dailyGlobalLimit,
    this.dailyUserLimit,
    this.updatedAt,
    this.updatedBy,
  });

  /// Fail-open default used before the doc loads / if it is missing.
  static const AiConfig fallback = AiConfig();

  bool get isServable => enabled && !maintenanceMode;

  String maintenanceMessage(String languageCode) {
    final ar = maintenanceMessageAr.trim();
    final en = maintenanceMessageEn.trim();
    if (languageCode == 'ar' && ar.isNotEmpty) return ar;
    if (en.isNotEmpty) return en;
    return ar.isNotEmpty ? ar : en;
  }

  factory AiConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AiConfig(
      enabled: data['enabled'] as bool? ?? true,
      maintenanceMode: data['maintenanceMode'] as bool? ?? false,
      maintenanceMessageEn: data['maintenanceMessageEn'] as String? ?? '',
      maintenanceMessageAr: data['maintenanceMessageAr'] as String? ?? '',
      dailyGlobalLimit: (data['dailyGlobalLimit'] as num?)?.toInt(),
      dailyUserLimit: (data['dailyUserLimit'] as num?)?.toInt(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}
