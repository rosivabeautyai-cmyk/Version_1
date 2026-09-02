/// Column mapping for feed / REST affiliate stores.
///
/// A `fieldMap` on the store document maps each ROSIVA canonical product
/// field to the column / property name used by that source. The backend
/// connectors merge it over their own defaults
/// (`ProductFeedConnector.DEFAULT_FIELD_MAP` /
/// `RestApiProductConnector` which requires an explicit map).
///
/// This file is the single Flutter-side source of truth for:
///   * which canonical keys exist and in what order the form shows them,
///   * which are mandatory before Save,
///   * the feed defaults used to prefill a fresh form,
///   * [autoMapColumns] — best-effort matching of detected source columns
///     to canonical keys after a successful Test Connection.
library;

/// Canonical product field keys, in the order the mapping editor shows
/// them. Mirrors the connector contract (see ProductFeedConnector.mjs /
/// RestApiProductConnector.mjs / normalizer.mjs).
const List<String> kAffiliateFieldMapKeys = [
  'externalProductId',
  'name',
  'productUrl',
  'affiliateUrl',
  'price',
  'currency',
  'brand',
  'description',
  'category',
  'imageUrl',
  'oldPrice',
  'salePrice',
  'availability',
  'rating',
  'reviewCount',
  'commissionRate',
];

/// Keys that MUST be mapped before a feed / REST store can be saved.
/// The URL rule is "at least one of productUrl / affiliateUrl" and is
/// enforced separately (see [affiliateFieldMapUrlSatisfied]).
const Set<String> kAffiliateFieldMapRequiredKeys = {
  'externalProductId',
  'name',
};

const List<String> kAffiliateFieldMapUrlKeys = ['productUrl', 'affiliateUrl'];

/// Feed defaults — identical to `DEFAULT_FIELD_MAP` in
/// `scripts/affiliate-sync/connectors/ProductFeedConnector.mjs`. Used to
/// prefill a new Product Feed / Affiliate Network form so a feed that
/// already uses these column names needs no manual mapping.
const Map<String, String> kAffiliateFieldMapFeedDefaults = {
  'externalProductId': 'id',
  'name': 'name',
  'description': 'description',
  'brand': 'brand',
  'category': 'category',
  'price': 'price',
  'oldPrice': 'rrp_price',
  'salePrice': 'sale_price',
  'currency': 'currency',
  'imageUrl': 'image_url',
  'productUrl': 'url',
  'affiliateUrl': 'deep_link',
  'availability': 'in_stock',
  'rating': 'rating',
  'reviewCount': 'reviews',
  'commissionRate': 'commission',
};

/// True when the URL requirement is met: at least one of productUrl /
/// affiliateUrl is mapped to a non-empty column.
bool affiliateFieldMapUrlSatisfied(Map<String, String> map) =>
    kAffiliateFieldMapUrlKeys.any((k) => (map[k] ?? '').trim().isNotEmpty);

/// Canonical keys that are still missing a mapping in [map] (required
/// scalar keys + the URL rule collapsed to the key 'productUrl' when
/// neither URL field is set). Empty => the map is good to save.
List<String> affiliateFieldMapMissing(Map<String, String> map) {
  final missing = <String>[
    for (final k in kAffiliateFieldMapRequiredKeys)
      if ((map[k] ?? '').trim().isEmpty) k,
  ];
  if (!affiliateFieldMapUrlSatisfied(map)) missing.add('productUrl');
  return missing;
}

String _norm(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');

/// Source column-name synonyms per canonical key, checked after an exact
/// (normalized) match. Order within a list is preference order.
const Map<String, List<String>> _kAffiliateColumnSynonyms = {
  'externalProductId': [
    'id', 'sku', 'productid', 'product_id', 'productcode', 'product_code',
    'itemid', 'item_id', 'ean', 'gtin', 'mpn', 'aw_product_id', 'merchant_product_id',
  ],
  'name': [
    'name', 'title', 'productname', 'product_name', 'producttitle',
    'product_title', 'itemname', 'item_name',
  ],
  'productUrl': [
    'url', 'link', 'producturl', 'product_url', 'productlink', 'product_link',
    'buyurl', 'buy_url', 'landingurl', 'landing_url', 'clickurl', 'click_url',
    'merchant_deep_link', 'weburl',
  ],
  'affiliateUrl': [
    'deeplink', 'deep_link', 'affiliateurl', 'affiliate_url', 'trackingurl',
    'tracking_url', 'aw_deep_link', 'clickthrough', 'clickthru',
  ],
  'price': [
    'price', 'saleprice', 'sale_price', 'currentprice', 'current_price',
    'priceamount', 'price_amount', 'search_price', 'display_price', 'now_price',
  ],
  'currency': ['currency', 'currencycode', 'currency_code', 'pricecurrency', 'price_currency'],
  'brand': ['brand', 'brandname', 'brand_name', 'manufacturer', 'vendor', 'make'],
  'description': [
    'description', 'desc', 'productdescription', 'product_description',
    'summary', 'longdescription', 'long_description', 'shortdescription',
  ],
  'category': [
    'category', 'categoryname', 'category_name', 'merchantcategory',
    'merchant_category', 'producttype', 'product_type', 'categories',
    'google_product_category', 'category_path',
  ],
  'imageUrl': [
    'imageurl', 'image_url', 'image', 'imagelink', 'image_link', 'mainimage',
    'main_image', 'picture', 'thumbnail', 'large_image', 'merchant_image_url',
  ],
  'oldPrice': [
    'rrp_price', 'rrp', 'rrpprice', 'waslprice', 'was_price', 'wasprice',
    'listprice', 'list_price', 'regularprice', 'regular_price', 'oldprice',
    'old_price', 'originalprice', 'original_price', 'msrp',
  ],
  'salePrice': [
    'saleprice', 'sale_price', 'specialprice', 'special_price', 'discountprice',
    'discount_price', 'offerprice', 'offer_price',
  ],
  'availability': [
    'instock', 'in_stock', 'availability', 'stock', 'stockstatus',
    'stock_status', 'isinstock', 'is_in_stock', 'available',
  ],
  'rating': ['rating', 'averagerating', 'average_rating', 'reviewscore', 'review_score', 'stars'],
  'reviewCount': [
    'reviews', 'reviewcount', 'review_count', 'ratingscount', 'ratings_count',
    'numberofreviews', 'number_of_reviews', 'reviewscount',
  ],
  'commissionRate': [
    'commission', 'commissionrate', 'commission_rate', 'commissionamount',
    'commission_amount', 'commissionpercent', 'commission_percent',
  ],
};

/// Best-effort mapping of [detectedColumns] (raw source column names from
/// a successful Test Connection) to canonical keys.
///
/// Per key: keep a still-valid [current] value; else an exact
/// normalized match; else the first synonym present in the columns;
/// else leave unset. Never invents a column that isn't in
/// [detectedColumns]. Returns only the keys it could fill.
Map<String, String> autoMapColumns(
  List<String> detectedColumns, {
  Map<String, String> current = const {},
}) {
  final byNorm = <String, String>{};
  for (final col in detectedColumns) {
    final n = _norm(col);
    if (n.isNotEmpty) byNorm.putIfAbsent(n, () => col);
  }

  final result = <String, String>{};
  for (final key in kAffiliateFieldMapKeys) {
    final existing = (current[key] ?? '').trim();
    if (existing.isNotEmpty && detectedColumns.contains(existing)) {
      result[key] = existing;
      continue;
    }
    final exact = byNorm[_norm(key)];
    if (exact != null) {
      result[key] = exact;
      continue;
    }
    for (final syn in _kAffiliateColumnSynonyms[key] ?? const <String>[]) {
      final hit = byNorm[_norm(syn)];
      if (hit != null) {
        result[key] = hit;
        break;
      }
    }
  }
  return result;
}
