import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_query.dart';
import '../services/product_api_service.dart';

/// Business-logic layer between the catalog API and every product
/// provider. Screens/providers should only ever talk to this
/// repository, never to [ProductApiService] directly.
class ProductRepository {
  final ProductApiService _service;

  ProductRepository({ProductApiService? service})
      : _service = service ?? ProductApiService();

  Future<List<CategoryModel>> getCategories() => _service.fetchCategories();

  Future<ProductPage<ProductModel>> getProducts(ProductQuery query) async {
    final items = await _service.fetchProducts(query);
    return ProductPage<ProductModel>(
      items: items,
      hasMore: items.length >= query.limit,
      page: query.page,
    );
  }

  Future<ProductModel> getProductDetails(String id) =>
      _service.fetchProductDetails(id);

  /// Fetches full product details for a list of ids (e.g. a user's
  /// favorites), skipping any that fail to load rather than failing
  /// the whole list.
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await _service.fetchProductDetails(id);
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<ProductModel>().toList();
  }
}
