import 'package:rosivia/core/network/api_client.dart';
import 'package:rosivia/core/network/app_config.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_query.dart';

/// Thin wrapper around [ApiClient] describing the ROSIVA catalog
/// endpoints. Contains no business logic — that lives in
/// [ProductRepository]. Every product/category shown in the app
/// flows through here; nothing is ever hardcoded.
class ProductApiService {
  final ApiClient _client;

  ProductApiService({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: AppConfig.productsApiBaseUrl);

  /// GET /categories
  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client.get('/categories');
    final list = _extractList(response);
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /products?category=&query=&sort=&page=&limit=
  Future<List<ProductModel>> fetchProducts(ProductQuery query) async {
    final response = await _client.get(
      '/products',
      queryParameters: query.toQueryParameters(),
    );
    final list = _extractList(response);
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /products/{id}
  Future<ProductModel> fetchProductDetails(String id) async {
    final response = await _client.get('/products/$id');
    final map = response is Map<String, dynamic>
        ? response
        : (response as Map).cast<String, dynamic>();
    return ProductModel.fromJson(map);
  }

  /// Accepts either a raw JSON array response or an `{ "items": [...] }`
  /// / `{ "data": [...] }` envelope, so the app isn't locked to one
  /// exact backend response shape while the API is still being built.
  List<dynamic> _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      final map = response;
      for (final key in ['items', 'data', 'results', 'products', 'categories']) {
        final value = map[key];
        if (value is List) return value;
      }
    }
    return const [];
  }
}
