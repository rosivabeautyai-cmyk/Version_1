import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../products/data/models/product_model.dart';
import '../models/activity_log_entry.dart';
import '../models/admin_dashboard_metrics.dart';
import '../models/admin_product_query.dart';
import '../models/ai_config_model.dart';
import '../models/country_config_model.dart';
import '../models/currency_config_model.dart';

/// The single choke point for every Admin-panel Firestore read/write.
///
/// Writes here only ever touch fields `firestore.rules` allows an
/// admin to write:
///  * `products/{id}` — the admin-managed keys only (`productType`,
///    `featured`, `active`, `adminNote`, `adminOverrides`,
///    `countryOffers`, `hasCountryOffers`, plus `adminUpdatedAt`/
///    `adminUpdatedBy`/`source`). Base fields (`price`, `name`, …) stay
///    owned by the Awin sync; corrections go into `adminOverrides` and
///    are layered on read by [ProductModel.fromJson].
///  * `countries/{code}`, `currencies/{code}`, `app_config/ai`
///  * `users/{uid}.disabled` — advisory flag; does NOT block Firebase
///    Auth sign-in on its own (needs a Cloud Function / the console).
///  * `activity_log/{id}` — append-only audit entries, logged as the
///    acting admin at server time (rules pin both).
class AdminRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AdminRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  // ---------------------------------------------------------------------
  // Activity log
  // ---------------------------------------------------------------------

  /// Best-effort append to the audit trail. Never throws / never blocks
  /// the mutation it records — a logging failure must not fail an admin
  /// action. Secrets must never be passed in [metadata].
  Future<void> logActivity({
    required String action,
    required String entityType,
    String? entityId,
    String summary = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('activity_log').add({
        'actorUid': uid,
        'action': action,
        'entityType': entityType,
        'entityId': ?entityId,
        'summary': summary,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // swallow — audit logging is best-effort
    }
  }

  Future<({List<ActivityLogEntry> items, String? cursorId, bool hasMore})>
      fetchActivity({int limit = 30, String? afterId}) async {
    Query<Map<String, dynamic>> q = _db
        .collection('activity_log')
        .orderBy('createdAt', descending: true);
    if (afterId != null) {
      final cursor = await _db.collection('activity_log').doc(afterId).get();
      if (cursor.exists) q = q.startAfterDocument(cursor);
    }
    final snap = await q.limit(limit).get();
    return (
      items: snap.docs.map(ActivityLogEntry.fromDoc).toList(),
      cursorId: snap.docs.isEmpty ? afterId : snap.docs.last.id,
      hasMore: snap.docs.length >= limit,
    );
  }

  // ---------------------------------------------------------------------
  // Country / currency config
  // ---------------------------------------------------------------------

  Stream<List<CountryConfig>> watchCountries() {
    return _db.collection('countries').snapshots().map((snap) {
      final list = snap.docs.map(CountryConfig.fromDoc).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<List<CountryConfig>> loadCountries() async {
    final snap = await _db.collection('countries').get();
    return snap.docs.map(CountryConfig.fromDoc).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> upsertCountry(CountryConfig country) async {
    await _db
        .collection('countries')
        .doc(country.code.toUpperCase())
        .set(country.toWriteMap(), SetOptions(merge: true));
    await logActivity(
      action: ActivityAction.countryConfigChanged,
      entityType: 'country',
      entityId: country.code.toUpperCase(),
      summary: 'Country ${country.code.toUpperCase()} saved',
    );
  }

  Future<void> setCountryEnabled(String code, bool enabled) async {
    await _db
        .collection('countries')
        .doc(code.toUpperCase())
        .set({'enabled': enabled}, SetOptions(merge: true));
    await logActivity(
      action: ActivityAction.countryConfigChanged,
      entityType: 'country',
      entityId: code.toUpperCase(),
      summary: '${code.toUpperCase()} ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  Stream<List<CurrencyConfig>> watchCurrencies() {
    return _db.collection('currencies').snapshots().map(
          (snap) => snap.docs.map(CurrencyConfig.fromDoc).toList()
            ..sort((a, b) => a.code.compareTo(b.code)),
        );
  }

  Future<List<CurrencyConfig>> loadCurrencies() async {
    final snap = await _db.collection('currencies').get();
    return snap.docs.map(CurrencyConfig.fromDoc).toList();
  }

  Future<void> upsertCurrency(CurrencyConfig currency) async {
    await _db
        .collection('currencies')
        .doc(currency.code.toUpperCase())
        .set(currency.toWriteMap(), SetOptions(merge: true));
    await logActivity(
      action: ActivityAction.currencyConfigChanged,
      entityType: 'currency',
      entityId: currency.code.toUpperCase(),
      summary: 'Currency ${currency.code.toUpperCase()} saved',
    );
  }

  Future<void> setCurrencyRate(String code, double? rateToUsd) async {
    await _db.collection('currencies').doc(code.toUpperCase()).set({
      'rateToUsd': rateToUsd,
      'rateUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await logActivity(
      action: ActivityAction.currencyConfigChanged,
      entityType: 'currency',
      entityId: code.toUpperCase(),
      summary: '${code.toUpperCase()} rate set to ${rateToUsd ?? 'none'}',
    );
  }

  // ---------------------------------------------------------------------
  // AI config (app_config/ai)
  // ---------------------------------------------------------------------

  Stream<AiConfig> watchAiConfig() {
    return _db.collection('app_config').doc('ai').snapshots().map(
          (doc) => doc.exists ? AiConfig.fromDoc(doc) : AiConfig.fallback,
        );
  }

  Future<void> updateAiConfig({
    bool? enabled,
    bool? maintenanceMode,
    String? maintenanceMessageEn,
    String? maintenanceMessageAr,
    Object? dailyGlobalLimit = _unset, // int? — omit to leave unchanged
    Object? dailyUserLimit = _unset, // int?
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (_uid != null) 'updatedBy': _uid,
    };
    if (enabled != null) data['enabled'] = enabled;
    if (maintenanceMode != null) data['maintenanceMode'] = maintenanceMode;
    if (maintenanceMessageEn != null) {
      data['maintenanceMessageEn'] = maintenanceMessageEn;
    }
    if (maintenanceMessageAr != null) {
      data['maintenanceMessageAr'] = maintenanceMessageAr;
    }
    if (!identical(dailyGlobalLimit, _unset)) {
      data['dailyGlobalLimit'] = dailyGlobalLimit; // null = unlimited
    }
    if (!identical(dailyUserLimit, _unset)) {
      data['dailyUserLimit'] = dailyUserLimit;
    }
    await _db
        .collection('app_config')
        .doc('ai')
        .set(data, SetOptions(merge: true));
    await logActivity(
      action: ActivityAction.aiConfigChanged,
      entityType: 'app_config',
      entityId: 'ai',
      summary: [
        if (enabled != null) 'enabled=$enabled',
        if (maintenanceMode != null) 'maintenance=$maintenanceMode',
        if (!identical(dailyGlobalLimit, _unset))
          'globalLimit=${dailyGlobalLimit ?? 'none'}',
        if (!identical(dailyUserLimit, _unset))
          'userLimit=${dailyUserLimit ?? 'none'}',
      ].join(' '),
    );
  }

  // ---------------------------------------------------------------------
  // Products (admin view — NOT filtered to the women-only catalog)
  // ---------------------------------------------------------------------

  Future<AdminProductPage> fetchProductsAdmin(
    AdminProductQuery query, {
    String? afterId,
  }) async {
    Query<Map<String, dynamic>> q = _products;
    if (query.category != null && query.category!.isNotEmpty) {
      q = q.where('rosivaCategory', isEqualTo: query.category);
    }
    q = q.orderBy('syncedAt', descending: true);

    if (afterId != null) {
      final cursorDoc = await _products.doc(afterId).get();
      if (cursorDoc.exists) q = q.startAfterDocument(cursorDoc);
    }

    final fetchLimit = query.hasClientFilter ? query.limit * 4 : query.limit;
    q = q.limit(fetchLimit.clamp(query.limit, 200));

    final snap = await q.get();
    final rawDocs = snap.docs;
    final parsed = rawDocs
        .map((d) => ProductModel.fromJson(d.data()))
        .where(query.matches)
        .toList();

    return AdminProductPage(
      items: parsed.take(query.limit).toList(),
      hasMore: rawDocs.length >= fetchLimit,
      cursorId: rawDocs.isEmpty ? afterId : rawDocs.last.id,
    );
  }

  Future<ProductModel> fetchProductAdmin(String id) async {
    return ProductModel.fromJson(await fetchProductRaw(id));
  }

  Future<Map<String, dynamic>> fetchProductRaw(String id) async {
    final doc = await _products.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw StateError('Product $id not found');
    }
    return data;
  }

  /// Creates an admin-authored product. `source: 'admin'` is mandatory
  /// (the security rule enforces it). Base fields are written directly
  /// (there is no Awin sync to fight for an admin product).
  Future<String> createProduct({
    required String name,
    String? brand,
    String? description,
    String? imageUrl,
    double? price,
    String currency = 'USD',
    String? storeUrl,
    required String rosivaCategory,
    String gender = 'women',
    String? productType,
    bool featured = false,
    bool active = true,
    String? adminNote,
    Map<String, dynamic> countryOffers = const {},
  }) async {
    final ref = _products.doc();
    await ref.set({
      'id': ref.id,
      'source': 'admin',
      'name': name.trim(),
      if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (imageUrl != null && imageUrl.trim().isNotEmpty)
        'imageUrl': imageUrl.trim(),
      'price': price,
      'currency': currency.toUpperCase(),
      if (storeUrl != null && storeUrl.trim().isNotEmpty)
        'storeUrl': storeUrl.trim(),
      'rosivaCategory': rosivaCategory,
      'category': rosivaCategory,
      'gender': gender,
      // Admin products are not classifier-vetted, so they are excluded
      // from the AI catalog by default (isRosivaProduct == false).
      'isRosivaProduct': false,
      if (productType != null && productType.trim().isNotEmpty)
        'productType': productType.trim(),
      'featured': featured,
      'active': active,
      if (adminNote != null && adminNote.trim().isNotEmpty)
        'adminNote': adminNote.trim(),
      if (countryOffers.isNotEmpty) 'countryOffers': countryOffers,
      'hasCountryOffers': countryOffers.isNotEmpty,
      'inStock': active,
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
      'adminUpdatedAt': FieldValue.serverTimestamp(),
      if (_uid != null) 'adminUpdatedBy': _uid,
    });
    await logActivity(
      action: ActivityAction.productCreated,
      entityType: 'product',
      entityId: ref.id,
      summary: 'Created product "${name.trim()}"',
    );
    return ref.id;
  }

  /// Writes ONLY the admin-managed product fields.
  Future<void> updateProductAdmin(
    String id, {
    Object? productType = _unset, // String?
    bool? featured,
    bool? active,
    Object? adminNote = _unset, // String?
    Map<String, dynamic>? adminOverrides,
    Map<String, dynamic>? countryOffers,
    String? activitySummary,
  }) async {
    final data = <String, dynamic>{
      'adminUpdatedAt': FieldValue.serverTimestamp(),
      if (_uid != null) 'adminUpdatedBy': _uid,
    };
    if (!identical(productType, _unset)) {
      data['productType'] = (productType as String?)?.trim().isEmpty ?? true
          ? FieldValue.delete()
          : (productType as String).trim();
    }
    if (featured != null) data['featured'] = featured;
    if (active != null) data['active'] = active;
    if (!identical(adminNote, _unset)) {
      data['adminNote'] = (adminNote as String?)?.trim().isEmpty ?? true
          ? FieldValue.delete()
          : (adminNote as String).trim();
    }
    if (adminOverrides != null) {
      data['adminOverrides'] =
          adminOverrides.isEmpty ? FieldValue.delete() : adminOverrides;
    }
    if (countryOffers != null) {
      data['countryOffers'] =
          countryOffers.isEmpty ? FieldValue.delete() : countryOffers;
      data['hasCountryOffers'] = countryOffers.isNotEmpty;
    }
    // mergeFields so a map field like `adminOverrides` is REPLACED
    // wholesale; the key list matches `firestore.rules` exactly.
    await _products.doc(id).set(
          data,
          SetOptions(mergeFields: data.keys.toList()),
        );

    final action = active == false
        ? ActivityAction.productDeactivated
        : active == true
            ? ActivityAction.productReactivated
            : countryOffers != null
                ? ActivityAction.countryOffersChanged
                : ActivityAction.productUpdated;
    await logActivity(
      action: action,
      entityType: 'product',
      entityId: id,
      summary: activitySummary ?? 'Product $id updated',
    );
  }

  static const Object _unset = Object();
  static Object get unset => _unset;

  // ---------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------

  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _db
        .collection('users')
        .doc(uid)
        .set({'disabled': disabled}, SetOptions(merge: true));
    await logActivity(
      action: disabled ? ActivityAction.userDisabled : ActivityAction.userEnabled,
      entityType: 'user',
      entityId: uid,
      summary: 'User $uid ${disabled ? 'disabled' : 'enabled'}',
    );
  }

  // ---------------------------------------------------------------------
  // Dashboard metrics
  // ---------------------------------------------------------------------

  Future<AdminDashboardMetrics> loadDashboardMetrics() async {
    Future<int?> countOf(Query<Map<String, dynamic>> q) async {
      try {
        final r = await q.count().get();
        return r.count;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      countOf(_products),
      countOf(_products.where('rosivaCategory', isEqualTo: 'skincare')),
      countOf(_products.where('rosivaCategory', isEqualTo: 'makeup')),
      countOf(_products.where('rosivaCategory', isEqualTo: 'perfume')),
      countOf(_products.where('featured', isEqualTo: true)),
      countOf(_products.where('isRosivaProduct', isEqualTo: false)),
      countOf(_products.where('storeUrl', isNull: true)),
      countOf(_products.where('price', isNull: true)),
      countOf(_products.where('active', isEqualTo: false)),
    ]);

    return AdminDashboardMetrics(
      totalProducts: results[0],
      skincareCount: results[1],
      makeupCount: results[2],
      perfumeCount: results[3],
      featuredCount: results[4],
      ineligibleCount: results[5],
      missingAffiliateCount: results[6],
      missingPriceCount: results[7],
      inactiveCount: results[8],
    );
  }

  /// Per-country tally, computed from the (small) set of products that
  /// carry any country offer — flagged by `hasCountryOffers == true`,
  /// so this reads only that subset, not the whole catalog, and needs
  /// no composite index.
  Future<List<CountryProductTally>> loadProductsByCountry(
    List<String> enabledCountryCodes,
  ) async {
    if (enabledCountryCodes.isEmpty) return const [];
    List<ProductModel> withOffers;
    try {
      final snap = await _products
          .where('hasCountryOffers', isEqualTo: true)
          .limit(1000)
          .get();
      withOffers = snap.docs.map((d) => ProductModel.fromJson(d.data())).toList();
    } catch (_) {
      return const [];
    }

    return [
      for (final code in enabledCountryCodes)
        () {
          var withOffer = 0, inStock = 0, outOfStock = 0, missingUrl = 0;
          for (final p in withOffers) {
            final offer = p.countryOffers[code.toUpperCase()];
            if (offer == null) continue;
            withOffer++;
            if (offer.inStock) {
              inStock++;
            } else {
              outOfStock++;
            }
            if ((offer.affiliateUrl ?? '').isEmpty) missingUrl++;
          }
          return CountryProductTally(
            countryCode: code.toUpperCase(),
            withOffer: withOffer,
            inStock: inStock,
            outOfStock: outOfStock,
            missingAffiliateUrl: missingUrl,
          );
        }(),
    ];
  }
}

class CountryProductTally {
  final String countryCode;
  final int withOffer;
  final int inStock;
  final int outOfStock;
  final int missingAffiliateUrl;

  const CountryProductTally({
    required this.countryCode,
    required this.withOffer,
    required this.inStock,
    required this.outOfStock,
    required this.missingAffiliateUrl,
  });
}
