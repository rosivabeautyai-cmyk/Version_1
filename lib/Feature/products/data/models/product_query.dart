/// Filter/sort/pagination parameters sent to `GET /products`.
class ProductQuery {
  final String? category;
  final String? searchTerm;
  final String? sort;
  final int page;
  final int limit;

  const ProductQuery({
    this.category,
    this.searchTerm,
    this.sort,
    this.page = 1,
    this.limit = 20,
  });

  ProductQuery copyWith({
    String? category,
    String? searchTerm,
    String? sort,
    int? page,
    int? limit,
  }) {
    return ProductQuery(
      category: category ?? this.category,
      searchTerm: searchTerm ?? this.searchTerm,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
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
