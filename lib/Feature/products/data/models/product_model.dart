import 'category_model.dart' show normalizeCategory;
import 'country_offer_model.dart';

/// A single beauty product as returned by the ROSIVA catalog API.
///
/// Every field is nullable/defaulted on purpose: the backend is the
/// single source of truth, and the UI must render sensible
/// loading/empty states rather than assume any field is always
/// present.
///
/// ### Admin overrides
/// The `products` collection is rewritten daily by the Awin sync, so
/// admin corrections to sync-owned fields (`price`, `currency`,
/// `storeUrl`, `name`, `brand`, `description`, `imageUrl`) are stored
/// in a separate `adminOverrides` map and **layered on top here at
/// parse time** — the sync never fights the admin, and every reader
/// (shopper UI, AI results) automatically sees the corrected value.
/// `adminOverrides` can NOT change `rosivaCategory` / `isRosivaProduct`
/// / `gender` — those stay owned by the classifier.
class ProductModel {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final double? price;
  final String currency;
  final String? imageUrl;
  final List<String> images;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final List<String> tags;
  final List<String> ingredients;
  final String? benefits;
  final String? howToUse;
  final String? whyRecommended;
  final bool isEditorsChoice;
  final String? storeUrl;
  final bool inStock;

  /// Affiliate / deep link used for "Shop Now" when present, in
  /// preference to [storeUrl]. Populated by the affiliate sync engine
  /// (scripts/affiliate-sync). Falls back to [storeUrl] for legacy /
  /// Awin-legacy / admin-authored products that only have that field.
  final String? affiliateUrl;

  /// The plain merchant product page (no affiliate tracking). Optional;
  /// informational only — "Shop Now" never uses this in preference to
  /// [affiliateUrl].
  final String? productUrl;

  /// Which pipeline created this document: `awin` (legacy sync),
  /// `affiliate` (generalized sync engine), `admin` (hand-authored), or
  /// null for pre-existing documents.
  final String? source;

  /// The affiliate store this product was imported from
  /// (`affiliateStores/{storeId}`). Null for legacy / admin products.
  final String? storeId;

  /// Stable id of the product in the external source. Combined with
  /// [storeId] this is the document id for imported products.
  final String? externalProductId;

  /// Availability as reported by the source: `in_stock` / `out_of_stock`
  /// / `unknown`. Separate from [inStock] (a bool) for round-tripping.
  final String? availability;

  /// Configured commission metadata for this product (NOT confirmed
  /// earnings). Resolved by priority product > store > system in the
  /// backend normalizer.
  final num? commissionRate;

  /// Hard visibility flag owned by the sync engine: a product the
  /// trusted source stopped returning is set to `false` (never hard
  /// deleted). Defaults to `true` so every pre-existing document — which
  /// has no `isActive` key — behaves exactly as before.
  final bool isActive;

  /// Whether this product is in ROSIVA's beauty scope at all — set by
  /// the Awin sync/backfill classifier, completely separate from
  /// [category]. Defaults to `true` for any document that predates
  /// this field.
  final bool isRosivaProduct;

  /// Who the product is marketed at — `women` / `men` / `unisex` /
  /// `unknown`. Never affects [isRosivaProduct]/[category].
  final String gender;

  /// Admin-managed. A short product-type keyword (e.g. `mascara`,
  /// `face serum`) — finer-grained than [category]. Null until an
  /// admin sets it.
  final String? productType;

  /// Admin-managed "highlight this product" flag. Falls back to the
  /// legacy [isEditorsChoice] when no explicit `featured` value exists.
  final bool featured;

  /// Admin-managed visibility flag ("soft delete" = `active == false`).
  /// Falls back to [inStock] when no explicit `active` value exists so
  /// pre-existing documents behave exactly as before.
  final bool active;

  /// Admin-only free-text note (not shown to shoppers).
  final String? adminNote;

  /// Country-specific price / affiliate URL overrides, keyed by ISO
  /// country code. Empty for most products (they are globally
  /// available at the default [price]/[storeUrl]).
  final Map<String, CountryOffer> countryOffers;

  const ProductModel({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    this.price,
    this.currency = 'USD',
    this.imageUrl,
    this.images = const [],
    this.rating,
    this.reviewCount,
    this.category,
    this.tags = const [],
    this.ingredients = const [],
    this.benefits,
    this.howToUse,
    this.whyRecommended,
    this.isEditorsChoice = false,
    this.storeUrl,
    this.inStock = true,
    this.affiliateUrl,
    this.productUrl,
    this.source,
    this.storeId,
    this.externalProductId,
    this.availability,
    this.commissionRate,
    this.isActive = true,
    this.isRosivaProduct = true,
    this.gender = 'unknown',
    this.productType,
    this.featured = false,
    this.active = true,
    this.adminNote,
    this.countryOffers = const {},
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Admin overrides for sync-owned display fields, layered on top of
    // whatever the sync wrote. Only these keys are honored here.
    final overrides = json['adminOverrides'];
    T? ov<T>(String key) {
      if (overrides is Map && overrides[key] != null) return overrides[key] as T?;
      return null;
    }

    return ProductModel(
      id: (json['id'] ?? json['productId'] ?? '').toString(),
      name: ov<String>('name') ?? json['name'] as String? ?? '',
      brand: ov<String>('brand') ?? json['brand'] as String?,
      description: ov<String>('description') ?? json['description'] as String?,
      price: _toDouble(ov<dynamic>('price') ?? json['price']),
      currency: ov<String>('currency') ?? json['currency'] as String? ?? 'USD',
      imageUrl: ov<String>('imageUrl') ??
          json['imageUrl'] as String? ??
          json['image'] as String?,
      images: _toStringList(json['images']),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount'] ?? json['reviewsCount']),
      // Normalized through the single canonical `normalizeCategory`.
      // `rosivaCategory` is authoritative; `category` is the legacy
      // fallback. Never overridable by admins.
      category: normalizeCategory(
        json['rosivaCategory'] as String? ?? json['category'] as String?,
      ),
      tags: _toStringList(json['tags']),
      ingredients: _toStringList(json['ingredients']),
      benefits: json['benefits'] as String?,
      howToUse: json['howToUse'] as String?,
      whyRecommended:
          json['whyRecommended'] as String? ?? json['aiReason'] as String?,
      isEditorsChoice: json['isEditorsChoice'] as bool? ?? false,
      storeUrl: ov<String>('storeUrl') ??
          json['storeUrl'] as String? ??
          json['affiliateUrl'] as String? ??
          json['url'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      affiliateUrl: ov<String>('affiliateUrl') ??
          json['affiliateUrl'] as String? ??
          json['storeUrl'] as String?,
      productUrl: json['productUrl'] as String? ?? json['url'] as String?,
      source: json['source'] as String?,
      storeId: json['storeId'] as String?,
      externalProductId: json['externalProductId'] as String?,
      availability: json['availability'] as String?,
      commissionRate: json['commissionRate'] as num?,
      isActive: json['isActive'] as bool? ?? true,
      isRosivaProduct: json['isRosivaProduct'] as bool? ?? true,
      gender: json['gender'] as String? ?? 'unknown',
      productType: json['productType'] as String?,
      featured: json['featured'] as bool? ??
          json['isEditorsChoice'] as bool? ??
          false,
      active: json['active'] as bool? ?? json['inStock'] as bool? ?? true,
      adminNote: json['adminNote'] as String?,
      countryOffers: CountryOffer.mapFromJson(json['countryOffers']),
    );
  }

  /// Country-availability visibility (Pass 2, item 8):
  ///  * no [countryOffers] at all → available everywhere (never hide
  ///    the existing global catalog)
  ///  * [countryOffers] present → available only where an offer exists
  ///  * no country selected → always visible
  ///
  /// This is a presentation-layer filter only. It never affects
  /// [isRosivaProduct] / [gender] / [category].
  bool isAvailableIn(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return true;
    if (countryOffers.isEmpty) return true;
    return countryOffers.containsKey(countryCode.toUpperCase());
  }

  /// The price + currency + buy URL a shopper in [countryCode] should
  /// see: the country-specific offer when one is configured, otherwise
  /// the product's default fields. Never invents a converted price.
  ({double? price, String currency, String? storeUrl, bool inStock}) offerFor(
    String? countryCode,
  ) {
    final offer = countryCode == null
        ? null
        : countryOffers[countryCode.toUpperCase()];
    if (offer == null) {
      return (
        price: price,
        currency: currency,
        // "Shop Now" prefers the affiliate/deep link over the plain
        // merchant URL. `storeUrl` already holds the affiliate link for
        // imported products; `affiliateUrl` is the explicit field.
        storeUrl: affiliateUrl ?? storeUrl,
        inStock: inStock
      );
    }
    return (
      price: offer.price ?? price,
      currency: offer.currency ?? currency,
      storeUrl: offer.affiliateUrl ?? storeUrl,
      inStock: offer.inStock,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
