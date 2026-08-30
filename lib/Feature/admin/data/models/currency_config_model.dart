import 'package:cloud_firestore/cloud_firestore.dart';

/// A currency ROSIVA can display prices in — symbol, localized name,
/// and an optional exchange rate to USD used for *approximate*
/// conversion only (the merchant/affiliate store stays the source of
/// truth for what a shopper is actually charged).
///
/// Document id = ISO 4217 code (e.g. `EGP`). `rateToUsd` is the number
/// of USD one unit of this currency is worth (USD itself = 1.0). Null
/// means "no rate yet" — the UI then shows the listed price without an
/// approximate conversion instead of guessing.
class CurrencyConfig {
  final String code;
  final String symbol;
  final String nameEn;
  final String nameAr;
  final double? rateToUsd;
  final DateTime? rateUpdatedAt;

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameAr,
    this.rateToUsd,
    this.rateUpdatedAt,
  });

  bool get hasRate => rateToUsd != null && rateToUsd! > 0;

  String name(String languageCode) =>
      languageCode == 'ar' && nameAr.isNotEmpty ? nameAr : nameEn;

  factory CurrencyConfig.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CurrencyConfig(
      code: (data['code'] as String? ?? doc.id).toUpperCase(),
      symbol: data['symbol'] as String? ?? doc.id.toUpperCase(),
      nameEn: data['nameEn'] as String? ?? doc.id.toUpperCase(),
      nameAr: data['nameAr'] as String? ?? '',
      rateToUsd: (data['rateToUsd'] as num?)?.toDouble(),
      rateUpdatedAt: (data['rateUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'code': code.toUpperCase(),
        'symbol': symbol,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'rateToUsd': rateToUsd,
      };

  CurrencyConfig copyWith({
    String? symbol,
    String? nameEn,
    String? nameAr,
    double? rateToUsd,
  }) {
    return CurrencyConfig(
      code: code,
      symbol: symbol ?? this.symbol,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      rateToUsd: rateToUsd ?? this.rateToUsd,
      rateUpdatedAt: rateUpdatedAt,
    );
  }
}
