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

  /// ROSIVA has exactly 3 canonical categories — this is the single
  /// source of truth for the category LIST itself (not just each
  /// category's field values). The `categories` collection can
  /// accumulate stale/duplicate documents across sync iterations
  /// (different casing, leftovers from an older classifier pass), and
  /// naively returning every raw document is exactly what shows up as
  /// duplicated category tiles in the UI. So the LIST is always
  /// exactly these 3 canonical slugs, in this order, regardless of
  /// how many raw documents actually exist.
  ///
  /// `productCount` is deliberately NOT read from the `categories`
  /// documents at all — that cached field goes stale independently of
  /// the real eligible-product count (it reflected ~3x too many
  /// products after the classifier was tightened, since nothing
  /// re-derives it except a full backfill run) and there's no
  /// reliable way to tell a stale doc from a fresh one from the
  /// client. Instead each category's count is a real, live Firestore
  /// aggregate count of `isRosivaProduct == true AND rosivaCategory ==
  /// slug` — cheap (aggregate counts don't read full documents) and
  /// always accurate. `name`/`imageUrl` still come from the matching
  /// `categories` doc when one exists, purely for display.
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final categorySnapshot = await _categoriesRef.get();
      final metaBySlug = <String, CategoryModel>{};
      for (final doc in categorySnapshot.docs) {
        final parsed = CategoryModel.fromJson(doc.data());
        final canonicalSlug = normalizeCategory(parsed.slug);
        if (canonicalSlug == null) continue; // not one of our 3 — ignore
        // Last one wins for name/image if there happen to be
        // duplicates — those fields are cosmetic only; the count
        // below is what actually has to be correct.
        metaBySlug[canonicalSlug] = parsed;
      }

      final counts = await Future.wait(
        kRosivaCategories.map(
          (slug) => _productsRef
              .where('isRosivaProduct', isEqualTo: true)
              .where('rosivaCategory', isEqualTo: slug)
              .count()
              .get(),
        ),
      );

      return [
        for (var i = 0; i < kRosivaCategories.length; i++)
          CategoryModel(
            id: kRosivaCategories[i],
            slug: kRosivaCategories[i],
            name: (metaBySlug[kRosivaCategories[i]]?.name.isNotEmpty ?? false)
                ? metaBySlug[kRosivaCategories[i]]!.name
                : kRosivaCategories[i][0].toUpperCase() +
                    kRosivaCategories[i].substring(1),
            imageUrl: metaBySlug[kRosivaCategories[i]]?.imageUrl,
            productCount: counts[i].count ?? 0,
          ),
      ];
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

      // The classifier-aware backfill has been run against the full
      // catalog (isRosivaProduct/rosivaCategory/gender are set on
      // every document), so these are now the real, authoritative
      // fields to query on — never the legacy `category` field, which
      // reflects an older, looser classification pass and would pull
      // from a pool that's now ~73% ineligible after the stricter
      // re-classification. Both are applied server-side so pagination/
      // limits operate on the true eligible set, not a capped batch
      // of an unrelated field that then gets mostly filtered away
      // locally (that mismatch was the root cause of near-empty
      // category screens and AI search results).
      final hasSearch =
          query.searchTerm != null && query.searchTerm!.isNotEmpty;
      final fetchLimit =
          (hasSearch ? query.limit * 4 : query.limit * 2).clamp(query.limit, 100);

      Query<Map<String, dynamic>> firestoreQuery =
          _productsRef.where('isRosivaProduct', isEqualTo: true);

      if (normalizedCategory != null) {
        firestoreQuery = firestoreQuery.where(
          'rosivaCategory',
          isEqualTo: normalizedCategory,
        );
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

      // Defense-in-depth, not the primary gate (that's the server-side
      // `isRosivaProduct` filter above): the classifier already bakes
      // `gender == "women"` into `isRosivaProduct` itself, so this
      // should be structurally redundant — but re-checking here means
      // a future classifier change can never silently leak a men's/
      // unisex product through without this local filter catching it.
      items = items
          .where((p) => p.isRosivaProduct && p.gender == 'women')
          .toList();

      // Country-availability visibility (Pass 2): hide products that
      // carry country offers which intentionally exclude the shopper's
      // selected country. Products with no country offers stay visible
      // everywhere. Never touches the hard filters above.
      if (query.country != null && query.country!.isNotEmpty) {
        items = items.where((p) => p.isAvailableIn(query.country)).toList();
      }

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
