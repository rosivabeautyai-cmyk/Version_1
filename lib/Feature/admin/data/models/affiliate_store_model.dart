import 'package:cloud_firestore/cloud_firestore.dart';

/// Integration types an affiliate store can use to import products.
/// String values MUST match scripts/affiliate-sync/lib/constants.mjs
/// (except [mock], which the backend `getConnector()` factory accepts
/// as a special testing override, not part of `INTEGRATION_TYPES`).
enum AffiliateIntegrationType {
  productFeed('product_feed'),
  restApi('rest_api'),
  affiliateNetwork('affiliate_network'),
  manual('manual'),

  /// Testing only — the MockConnector generates deterministic sample
  /// beauty products with no third-party credentials, so the full
  /// pipeline (Test → Save → Sync → visible) can be verified end to end.
  mock('mock');

  const AffiliateIntegrationType(this.value);
  final String value;

  /// True for a source that supports automatic import (everything
  /// except [manual]).
  bool get supportsAutomaticImport => this != AffiliateIntegrationType.manual;

  static AffiliateIntegrationType fromValue(String? v) =>
      AffiliateIntegrationType.values.firstWhere(
        (e) => e.value == v,
        orElse: () => AffiliateIntegrationType.manual,
      );
}

/// How often the backend re-syncs the store. Values match
/// SYNC_FREQUENCIES in scripts/affiliate-sync/lib/constants.mjs.
enum AffiliateSyncFrequency {
  every6Hours('6_hours'),
  every12Hours('12_hours'),
  daily('daily'),
  weekly('weekly');

  const AffiliateSyncFrequency(this.value);
  final String value;

  static AffiliateSyncFrequency fromValue(String? v) =>
      AffiliateSyncFrequency.values.firstWhere(
        (e) => e.value == v,
        orElse: () => AffiliateSyncFrequency.daily,
      );
}

enum AffiliateCommissionType {
  percentage('percentage'),
  fixed('fixed');

  const AffiliateCommissionType(this.value);
  final String value;

  static AffiliateCommissionType fromValue(String? v) =>
      AffiliateCommissionType.values.firstWhere(
        (e) => e.value == v,
        orElse: () => AffiliateCommissionType.percentage,
      );
}

enum AffiliateFeedFormat {
  csv('csv'),
  xml('xml'),
  json('json');

  const AffiliateFeedFormat(this.value);
  final String value;

  static AffiliateFeedFormat fromValue(String? v) =>
      AffiliateFeedFormat.values.firstWhere(
        (e) => e.value == v,
        orElse: () => AffiliateFeedFormat.csv,
      );
}

/// An affiliate store / product source.
///
/// This model carries ONLY the public, non-secret configuration. Private
/// feed passwords, API keys and access tokens are NEVER stored on the
/// Firestore document or read into this model — they live in the backend
/// environment only (see docs/AFFILIATE_STORES.md).
///
/// Mirrors the `affiliateStores/{id}` document written/read by
/// scripts/affiliate-sync and server/src/routes/affiliateAdmin.js.
class AffiliateStore {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String? description;
  final String? websiteUrl;
  final String? country;
  final String currency;

  final String? affiliateNetwork;
  final String? programId;
  final String? affiliateId;

  final AffiliateIntegrationType integrationType;

  // Product-feed config (public only).
  final String? feedUrl;
  final AffiliateFeedFormat feedFormat;
  final String? feedAuthType; // none | basic | bearer
  final String? feedUsername; // password is backend-only
  final String? feedLanguage;
  final String? feedItemPath;

  // REST-API config (public only).
  final String? apiBaseUrl;
  final String? apiProductsPath;
  final String? apiAuthType; // none | bearer | header | query
  final String? apiAuthHeaderName;
  final String? apiAuthQueryParam;
  final String? publicApiId;
  final String? apiItemsPath;

  // Field mapping (raw ROSIVA key -> source column/path).
  final Map<String, String> fieldMap;

  final num defaultCommissionRate;
  final AffiliateCommissionType commissionType;

  final bool syncEnabled;
  final AffiliateSyncFrequency syncFrequency;

  final String status; // active | inactive
  final String syncStatus; // idle | queued | running | success | error

  final DateTime? lastSyncAt;
  final DateTime? nextSyncAt;
  final String? lastSyncStatus; // success | error | partial
  final String? lastSyncError;

  final int productCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AffiliateStore({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.description,
    this.websiteUrl,
    this.country,
    this.currency = 'USD',
    this.affiliateNetwork,
    this.programId,
    this.affiliateId,
    this.integrationType = AffiliateIntegrationType.manual,
    this.feedUrl,
    this.feedFormat = AffiliateFeedFormat.csv,
    this.feedAuthType,
    this.feedUsername,
    this.feedLanguage,
    this.feedItemPath,
    this.apiBaseUrl,
    this.apiProductsPath,
    this.apiAuthType,
    this.apiAuthHeaderName,
    this.apiAuthQueryParam,
    this.publicApiId,
    this.apiItemsPath,
    this.fieldMap = const {},
    this.defaultCommissionRate = 0,
    this.commissionType = AffiliateCommissionType.percentage,
    this.syncEnabled = true,
    this.syncFrequency = AffiliateSyncFrequency.daily,
    this.status = 'active',
    this.syncStatus = 'idle',
    this.lastSyncAt,
    this.nextSyncAt,
    this.lastSyncStatus,
    this.lastSyncError,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isManual => integrationType == AffiliateIntegrationType.manual;

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  factory AffiliateStore.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AffiliateStore.fromJson(doc.id, doc.data() ?? const {});

  factory AffiliateStore.fromJson(String id, Map<String, dynamic> d) {
    final rawMap = d['fieldMap'];
    return AffiliateStore(
      id: id,
      name: d['name'] as String? ?? id,
      slug: d['slug'] as String? ?? id,
      logoUrl: d['logoUrl'] as String?,
      description: d['description'] as String?,
      websiteUrl: d['websiteUrl'] as String?,
      country: d['country'] as String?,
      currency: (d['currency'] as String? ?? 'USD').toUpperCase(),
      affiliateNetwork: d['affiliateNetwork'] as String?,
      programId: d['programId'] as String?,
      affiliateId: d['affiliateId'] as String?,
      integrationType:
          AffiliateIntegrationType.fromValue(d['integrationType'] as String?),
      feedUrl: d['feedUrl'] as String?,
      feedFormat: AffiliateFeedFormat.fromValue(d['feedFormat'] as String?),
      feedAuthType: d['feedAuthType'] as String?,
      feedUsername: d['feedUsername'] as String?,
      feedLanguage: d['feedLanguage'] as String?,
      feedItemPath: d['feedItemPath'] as String?,
      apiBaseUrl: d['apiBaseUrl'] as String?,
      apiProductsPath: d['apiProductsPath'] as String?,
      apiAuthType: d['apiAuthType'] as String?,
      apiAuthHeaderName: d['apiAuthHeaderName'] as String?,
      apiAuthQueryParam: d['apiAuthQueryParam'] as String?,
      publicApiId: d['publicApiId'] as String?,
      apiItemsPath: d['apiItemsPath'] as String?,
      fieldMap: rawMap is Map
          ? rawMap.map((k, v) => MapEntry(k.toString(), v.toString()))
          : const {},
      defaultCommissionRate: (d['defaultCommissionRate'] as num?) ?? 0,
      commissionType:
          AffiliateCommissionType.fromValue(d['commissionType'] as String?),
      syncEnabled: d['syncEnabled'] as bool? ?? true,
      syncFrequency:
          AffiliateSyncFrequency.fromValue(d['syncFrequency'] as String?),
      status: d['status'] as String? ?? 'active',
      syncStatus: d['syncStatus'] as String? ?? 'idle',
      lastSyncAt: _date(d['lastSyncAt']),
      nextSyncAt: _date(d['nextSyncAt']),
      lastSyncStatus: d['lastSyncStatus'] as String?,
      lastSyncError: d['lastSyncError'] as String?,
      productCount: (d['productCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }

  /// The public config an admin may write. Deliberately excludes every
  /// sync-owned bookkeeping field (syncStatus, lastSyncAt, productCount…)
  /// and every private credential.
  Map<String, dynamic> toWriteMap() => {
        'name': name.trim(),
        'slug': slug.trim(),
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (description != null) 'description': description,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        if (country != null) 'country': country,
        'currency': currency.toUpperCase(),
        if (affiliateNetwork != null) 'affiliateNetwork': affiliateNetwork,
        if (programId != null) 'programId': programId,
        if (affiliateId != null) 'affiliateId': affiliateId,
        'integrationType': integrationType.value,
        if (feedUrl != null) 'feedUrl': feedUrl,
        'feedFormat': feedFormat.value,
        if (feedAuthType != null) 'feedAuthType': feedAuthType,
        if (feedUsername != null) 'feedUsername': feedUsername,
        if (feedLanguage != null) 'feedLanguage': feedLanguage,
        if (feedItemPath != null) 'feedItemPath': feedItemPath,
        if (apiBaseUrl != null) 'apiBaseUrl': apiBaseUrl,
        if (apiProductsPath != null) 'apiProductsPath': apiProductsPath,
        if (apiAuthType != null) 'apiAuthType': apiAuthType,
        if (apiAuthHeaderName != null) 'apiAuthHeaderName': apiAuthHeaderName,
        if (apiAuthQueryParam != null) 'apiAuthQueryParam': apiAuthQueryParam,
        if (publicApiId != null) 'publicApiId': publicApiId,
        if (apiItemsPath != null) 'apiItemsPath': apiItemsPath,
        if (fieldMap.isNotEmpty) 'fieldMap': fieldMap,
        'defaultCommissionRate': defaultCommissionRate,
        'commissionType': commissionType.value,
        'syncEnabled': syncEnabled,
        'syncFrequency': syncFrequency.value,
        'status': status,
      };

  AffiliateStore copyWith(Map<String, dynamic> patch) =>
      AffiliateStore.fromJson(id, {...toWriteMap(), ...patch, 'id': id});
}
