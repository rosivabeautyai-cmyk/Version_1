import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:rosivia/core/network/api_exception.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_query.dart';

/// Reads the ROSIVA product catalog directly from Firestore
/// (`products`/`categories` collections, populated by the
/// `syncAwinProducts` Cloud Function — see functions/src/awinSync.ts).
///
/// Keeps the exact same method signatures the previous REST-backed
/// implementation had, so [ProductRepository] and everything above it
/// (providers, screens, the AI product-search flow) never had to
/// change.
///
/// Firestore has no native full-text search, so [ProductQuery.searchTerm]
/// is applied as a local, case-insensitive filter over a slightly
/// larger fetched page rather than a server-side query — fine for a
/// catalog this size, but not a substitute for a real search index.
class ProductApiService {
  final FirebaseFirestore _firestore;

  ProductApiService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  /// Per-service-instance pagination cursors, keyed by the query
  /// "shape" (category + sort). Firestore paginates via document
  /// cursors, not numeric offsets, so this only supports the app's
  /// actual usage pattern — sequential `loadMore()` calls on the same
  /// provider instance — not jumping to an arbitrary page number.
  final Map<String, DocumentSnapshot<Map<String, dynamic>>?> _cursors = {};

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final snapshot = await _categoriesRef.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw ApiServerException(0, e.message);
    }
  }

  Future<List<ProductModel>> fetchProducts(ProductQuery query) async {
    try {
      // Always normalize before the equality filter — Firestore does
      // an exact string match server-side, so sending anything other
      // than the canonical lowercase slug actually stored on the
      // documents (e.g. "Makeup" instead of "makeup") would silently
      // match nothing rather than error.
      final normalizedCategory = normalizeCategory(query.category);

      final cursorKey = '$normalizedCategory|${query.sort}';
      if (query.page <= 1) {
        _cursors.remove(cursorKey);
      }

      final hasSearch =
          query.searchTerm != null && query.searchTerm!.isNotEmpty;
      final fetchLimit =
          hasSearch ? (query.limit * 4).clamp(query.limit, 80) : query.limit;

      Query<Map<String, dynamic>> firestoreQuery = _productsRef;

      if (normalizedCategory != null) {
        firestoreQuery =
            firestoreQuery.where('category', isEqualTo: normalizedCategory);
      }

      firestoreQuery = _applySort(firestoreQuery, query.sort);

      final cursor = _cursors[cursorKey];
      if (cursor != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(cursor);
      }

      firestoreQuery = firestoreQuery.limit(fetchLimit);

      final snapshot = await firestoreQuery.get();
      if (snapshot.docs.isNotEmpty) {
        _cursors[cursorKey] = snapshot.docs.last;
      }

      var items =
          snapshot.docs.map((doc) => ProductModel.fromJson(doc.data())).toList();

      if (hasSearch) {
        final term = query.searchTerm!.toLowerCase();
        items = items.where((p) {
          final haystack = [p.name, p.brand, p.category, ...p.tags]
              .whereType<String>()
              .join(' ')
              .toLowerCase();
          return haystack.contains(term);
        }).toList();
      }

      if (items.length > query.limit) {
        items = items.take(query.limit).toList();
      }

      return items;
    } on FirebaseException catch (e) {
      throw ApiServerException(0, e.message);
    }
  }

  Query<Map<String, dynamic>> _applySort(
    Query<Map<String, dynamic>> query,
    String? sort,
  ) {
    switch (sort) {
      case 'price_asc':
        return query.orderBy('price');
      case 'price_desc':
        return query.orderBy('price', descending: true);
      case 'newest':
        return query.orderBy('syncedAt', descending: true);
      case 'popular':
      case 'curated':
      case 'trending':
      default:
        return query.orderBy('rating', descending: true);
    }
  }

  Future<ProductModel> fetchProductDetails(String id) async {
    try {
      final doc = await _productsRef.doc(id).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        throw const ApiServerException(404, 'Product not found');
      }
      return ProductModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw ApiServerException(0, e.message);
    }
  }
}
