import 'package:cloud_firestore/cloud_firestore.dart';

/// A country ROSIVA operates in — the Firestore-backed source of truth
/// that replaces `RegionalPrefsProvider`'s hardcoded list.
///
/// Document id = ISO 3166-1 alpha-2 code (e.g. `EG`). Managed by admins
/// via the Admin panel; readable by any signed-in user.
class CountryConfig {
  final String code;
  final String nameEn;
  final String nameAr;

  /// ISO 4217 code of the currency used in this country (e.g. `EGP`).
  final String currencyCode;

  /// When false the country is hidden from the shopper country picker.
  final bool enabled;

  final int sortOrder;

  const CountryConfig({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.currencyCode,
    this.enabled = true,
    this.sortOrder = 999,
  });

  /// Localized display name. [languageCode] is `'ar'` or anything else
  /// (treated as English).
  String name(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  factory CountryConfig.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CountryConfig(
      code: (data['countryCode'] as String? ?? doc.id).toUpperCase(),
      nameEn: data['nameEn'] as String? ?? doc.id,
      nameAr: data['nameAr'] as String? ?? '',
      currencyCode: (data['currencyCode'] as String? ?? '').toUpperCase(),
      enabled: data['enabled'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 999,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'countryCode': code.toUpperCase(),
        'nameEn': nameEn,
        'nameAr': nameAr,
        'currencyCode': currencyCode.toUpperCase(),
        'enabled': enabled,
        'sortOrder': sortOrder,
      };

  CountryConfig copyWith({
    String? nameEn,
    String? nameAr,
    String? currencyCode,
    bool? enabled,
    int? sortOrder,
  }) {
    return CountryConfig(
      code: code,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      currencyCode: currencyCode ?? this.currencyCode,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
