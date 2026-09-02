import '../../../products/data/models/product_model.dart';

/// Filter set for the admin Products / Affiliate screens. Unlike the
/// shopper [ProductQuery], this deliberately does **not** apply the
/// women-only / `isRosivaProduct` catalog filter — an admin needs to
/// see and fix ineligible / men's / unisex products too.
class AdminProductQuery {
  /// `skincare` | `makeup` | `perfume` | null (all).
  final String? category;
  final String search;
  final bool onlyFeatured;
  final bool onlyInactive;
  final bool onlyIneligible;
  final bool missingAffiliate;
  final bool missingPrice;

  /// ISO country code — restricts to products that have a country
  /// offer for this country (used together with [hasCountryOffer] /
  /// [missingCountryOffer]).
  final String? country;

  /// ISO currency code — matches the product's effective currency OR
  /// any country-offer currency.
  final String? currency;

  final bool hasCountryOffer;
  final bool missingCountryOffer;
  final bool inStockOnly;
  final bool outOfStockOnly;

  /// Restrict to products imported from a specific affiliate store
  /// (`products.storeId`). Null = any source.
  final String? storeId;

  final int limit;

  const AdminProductQuery({
    this.category,
    this.search = '',
    this.onlyFeatured = false,
    this.onlyInactive = false,
    this.onlyIneligible = false,
    this.missingAffiliate = false,
    this.missingPrice = false,
    this.country,
    this.currency,
    this.hasCountryOffer = false,
    this.missingCountryOffer = false,
    this.inStockOnly = false,
    this.outOfStockOnly = false,
    this.storeId,
    this.limit = 40,
  });

  bool get hasClientFilter =>
      search.isNotEmpty ||
      onlyFeatured ||
      onlyInactive ||
      onlyIneligible ||
      missingAffiliate ||
      missingPrice ||
      country != null ||
      currency != null ||
      hasCountryOffer ||
      missingCountryOffer ||
      inStockOnly ||
      outOfStockOnly ||
      storeId != null;

  AdminProductQuery copyWith({
    String? category,
    bool clearCategory = false,
    String? search,
    bool? onlyFeatured,
    bool? onlyInactive,
    bool? onlyIneligible,
    bool? missingAffiliate,
    bool? missingPrice,
    String? country,
    bool clearCountry = false,
    String? currency,
    bool clearCurrency = false,
    bool? hasCountryOffer,
    bool? missingCountryOffer,
    bool? inStockOnly,
    bool? outOfStockOnly,
    String? storeId,
    bool clearStoreId = false,
  }) {
    return AdminProductQuery(
      category: clearCategory ? null : (category ?? this.category),
      search: search ?? this.search,
      onlyFeatured: onlyFeatured ?? this.onlyFeatured,
      onlyInactive: onlyInactive ?? this.onlyInactive,
      onlyIneligible: onlyIneligible ?? this.onlyIneligible,
      missingAffiliate: missingAffiliate ?? this.missingAffiliate,
      missingPrice: missingPrice ?? this.missingPrice,
      country: clearCountry ? null : (country ?? this.country),
      currency: clearCurrency ? null : (currency ?? this.currency),
      hasCountryOffer: hasCountryOffer ?? this.hasCountryOffer,
      missingCountryOffer: missingCountryOffer ?? this.missingCountryOffer,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      outOfStockOnly: outOfStockOnly ?? this.outOfStockOnly,
      storeId: clearStoreId ? null : (storeId ?? this.storeId),
      limit: limit,
    );
  }

  /// Applies the client-side portion of the filter to an already
  /// fetched page (the category is applied server-side).
  bool matches(ProductModel p) {
    if (onlyFeatured && !p.featured) return false;
    if (onlyInactive && p.active) return false;
    if (onlyIneligible && p.isRosivaProduct) return false;
    if (missingPrice && p.price != null) return false;
    if (storeId != null && p.storeId != storeId) return false;

    final anyOfferUrl =
        p.countryOffers.values.any((o) => (o.affiliateUrl ?? '').isNotEmpty);
    if (missingAffiliate) {
      if ((p.storeUrl ?? '').isNotEmpty || anyOfferUrl) return false;
    }

    if (hasCountryOffer && p.countryOffers.isEmpty) return false;
    if (missingCountryOffer && p.countryOffers.isNotEmpty) return false;

    if (country != null) {
      final cc = country!.toUpperCase();
      if (!p.countryOffers.containsKey(cc)) return false;
    }

    if (currency != null) {
      final want = currency!.toUpperCase();
      final effective = p.currency.toUpperCase();
      final offerCurrencies =
          p.countryOffers.values.map((o) => (o.currency ?? '').toUpperCase());
      if (effective != want && !offerCurrencies.contains(want)) return false;
    }

    if (inStockOnly || outOfStockOnly) {
      // "in stock" for a given country = that country's offer inStock,
      // else the product's own inStock/active.
      bool inStock;
      final cc = country?.toUpperCase();
      final offer = cc == null ? null : p.countryOffers[cc];
      inStock = offer?.inStock ?? (p.active && p.inStock);
      if (inStockOnly && !inStock) return false;
      if (outOfStockOnly && inStock) return false;
    }

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      final hay = [
        p.name,
        p.brand,
        p.category,
        p.productType,
        ...p.tags,
      ].whereType<String>().join(' ').toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }
}

/// A page of admin products plus the raw cursor id for "load more".
class AdminProductPage {
  final List<ProductModel> items;
  final bool hasMore;
  final String? cursorId;

  const AdminProductPage({
    required this.items,
    required this.hasMore,
    required this.cursorId,
  });
}
