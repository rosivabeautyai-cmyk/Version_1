/// A country-specific offer for a product: what it costs and where to
/// buy it in one country, overriding the product's default
/// price/currency/store link.
///
/// Stored as a map on `products/{id}.countryOffers` keyed by ISO
/// country code (e.g. `{ "EG": {price, currency, affiliateUrl,
/// inStock} }`). Admin-managed. The affiliate URL always remains the
/// source of truth for the actual purchase — an offer never implies
/// ROSIVA itself sells or ships anything.
class CountryOffer {
  final String countryCode;
  final double? price;
  final String? currency;
  final String? affiliateUrl;
  final bool inStock;

  const CountryOffer({
    required this.countryCode,
    this.price,
    this.currency,
    this.affiliateUrl,
    this.inStock = true,
  });

  factory CountryOffer.fromJson(String countryCode, Map<String, dynamic> json) {
    return CountryOffer(
      countryCode: countryCode.toUpperCase(),
      price: (json['price'] as num?)?.toDouble(),
      currency: (json['currency'] as String?)?.toUpperCase(),
      affiliateUrl: json['affiliateUrl'] as String? ?? json['storeUrl'] as String?,
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (price != null) 'price': price,
        if (currency != null && currency!.isNotEmpty) 'currency': currency,
        if (affiliateUrl != null && affiliateUrl!.isNotEmpty)
          'affiliateUrl': affiliateUrl,
        'inStock': inStock,
      };

  static Map<String, CountryOffer> mapFromJson(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, CountryOffer>{};
    raw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        out[key.toString().toUpperCase()] =
            CountryOffer.fromJson(key.toString(), value);
      } else if (value is Map) {
        out[key.toString().toUpperCase()] = CountryOffer.fromJson(
          key.toString(),
          value.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    });
    return out;
  }
}
