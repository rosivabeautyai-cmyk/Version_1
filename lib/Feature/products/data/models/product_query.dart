/// Filter/sort/pagination parameters sent to `GET /products`.
class ProductQuery {
  final String? category;
  final String? searchTerm;
  final String? sort;
  final int page;
  final int limit;

  /// The shopper's selected country (ISO code). When set, products
  /// that carry a `countryOffers` map which intentionally does NOT
  /// include this country are hidden. Products with no `countryOffers`
  /// stay visible everywhere (never hide the existing global catalog).
  /// This is a presentation-layer visibility filter only — it never
  /// touches `isRosivaProduct` / `gender` / `rosivaCategory`.
  final String? country;

  const ProductQuery({
    this.category,
    this.searchTerm,
    this.sort,
    this.page = 1,
    this.limit = 20,
    this.country,
  });

  ProductQuery copyWith({
    String? category,
    String? searchTerm,
    String? sort,
    int? page,
    int? limit,
    String? country,
  }) {
    return ProductQuery(
      category: category ?? this.category,
      searchTerm: searchTerm ?? this.searchTerm,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      if (category != null && category!.isNotEmpty) 'category': category,
      if (searchTerm != null && searchTerm!.isNotEmpty) 'query': searchTerm,
      if (sort != null && sort!.isNotEmpty) 'sort': sort,
      'page': page,
      'limit': limit,
    };
  }
}

/// A page of products plus whether more pages are available —
/// returned by [ProductRepository] so providers can drive infinite
/// scroll / "load more" without re-parsing raw JSON themselves.
class ProductPage<T> {
  final List<T> items;
  final bool hasMore;
  final int page;

  const ProductPage({
    required this.items,
    required this.hasMore,
    required this.page,
  });
}
