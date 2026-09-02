// Pure, Firestore-free unit tests for the Affiliate Stores feature:
//   * AffiliateStore.fromJson / toWriteMap  (enum parsing, no secret keys)
//   * AffiliateSyncFrequency / integration-type enum fallbacks
//   * AffiliateSyncLog.fromJson
//   * ProductModel: new affiliate fields + "Shop Now" URL preference
import 'package:flutter_test/flutter_test.dart';

import 'package:rosivia/Feature/admin/data/models/affiliate_store_model.dart';
import 'package:rosivia/Feature/admin/data/models/affiliate_sync_log_model.dart';
import 'package:rosivia/Feature/products/data/models/product_model.dart';

void main() {
  group('AffiliateStore', () {
    test('fromJson parses enums, currency, fieldMap and timestamps', () {
      final s = AffiliateStore.fromJson('shein', {
        'name': 'SHEIN',
        'slug': 'shein',
        'currency': 'usd',
        'affiliateNetwork': 'awin',
        'programId': 'P123',
        'integrationType': 'product_feed',
        'feedFormat': 'csv',
        'defaultCommissionRate': 8,
        'commissionType': 'percentage',
        'syncEnabled': true,
        'syncFrequency': '6_hours',
        'status': 'active',
        'syncStatus': 'success',
        'productCount': 18542,
        'lastSyncAt': '2026-09-02T10:00:00.000Z',
        'fieldMap': {'externalProductId': 'sku', 'name': 'title'},
      });
      expect(s.integrationType, AffiliateIntegrationType.productFeed);
      expect(s.syncFrequency, AffiliateSyncFrequency.every6Hours);
      expect(s.currency, 'USD');
      expect(s.productCount, 18542);
      expect(s.fieldMap['externalProductId'], 'sku');
      expect(s.lastSyncAt, isNotNull);
      expect(s.isActive, true);
    });

    test('unknown enum values fall back safely', () {
      final s = AffiliateStore.fromJson('x', {
        'name': 'X',
        'integrationType': 'quantum_teleport',
        'syncFrequency': 'every_fortnight',
        'commissionType': 'stock_options',
        'feedFormat': 'yaml',
      });
      expect(s.integrationType, AffiliateIntegrationType.manual);
      expect(s.syncFrequency, AffiliateSyncFrequency.daily);
      expect(s.commissionType, AffiliateCommissionType.percentage);
      expect(s.feedFormat, AffiliateFeedFormat.csv);
    });

    test('toWriteMap contains only public config — never a secret key', () {
      final s = AffiliateStore.fromJson('s', {
        'name': 'S',
        'slug': 's',
        'integrationType': 'product_feed',
        'feedUrl': 'https://feed.example/s.csv',
        'feedAuthType': 'basic',
        'feedUsername': 'pub123',
        'apiBaseUrl': 'https://api.example',
      });
      final map = s.toWriteMap();
      const forbidden = [
        'feedPassword',
        'feedSecret',
        'password',
        'apiKey',
        'apiSecret',
        'accessToken',
        'clientSecret',
        'token',
        'syncStatus',
        'productCount',
        'lastSyncAt',
      ];
      for (final k in forbidden) {
        expect(map.containsKey(k), isFalse, reason: '$k must not be written');
      }
      expect(map['feedUrl'], 'https://feed.example/s.csv');
      expect(map['feedUsername'], 'pub123'); // username is not a secret
      expect(map['integrationType'], 'product_feed');
    });

    test('copyWith round-trips through toWriteMap', () {
      final s = AffiliateStore.fromJson('s', {
        'name': 'S',
        'integrationType': 'rest_api',
        'defaultCommissionRate': 5,
      });
      final s2 = s.copyWith({'defaultCommissionRate': 12});
      expect(s2.defaultCommissionRate, 12);
      expect(s2.integrationType, AffiliateIntegrationType.restApi);
    });
  });

  group('AffiliateSyncLog', () {
    test('fromJson reads counters + failure samples', () {
      final log = AffiliateSyncLog.fromJson('log1', {
        'storeId': 'shein',
        'status': 'partial',
        'triggeredBy': 'scheduled',
        'totalFetched': 18542,
        'newProducts': 83,
        'updatedProducts': 421,
        'deactivatedProducts': 17,
        'failedProducts': 3,
        'errorSummary': '3 product(s) skipped',
        'startedAt': '2026-09-02T09:00:00.000Z',
        'completedAt': '2026-09-02T09:04:00.000Z',
        'failureSamples': [
          {'code': 'missing_product_url', 'detail': 'AW999'},
        ],
      });
      expect(log.isPartial, true);
      expect(log.newProducts, 83);
      expect(log.deactivatedProducts, 17);
      expect(log.triggeredBy, 'scheduled');
      expect(log.failureSamples.single['code'], 'missing_product_url');
    });
  });

  group('ProductModel affiliate fields', () {
    test('parses new fields; isActive defaults true for legacy docs', () {
      final legacy = ProductModel.fromJson({'id': 'p1', 'name': 'Legacy'});
      expect(legacy.isActive, true);
      expect(legacy.source, isNull);

      final imported = ProductModel.fromJson({
        'id': 'store_1:SKU9',
        'name': 'Imported Serum',
        'storeId': 'store_1',
        'externalProductId': 'SKU9',
        'source': 'affiliate',
        'availability': 'in_stock',
        'commissionRate': 12,
        'isActive': false,
        'productUrl': 'https://shop.example/p/SKU9',
        'affiliateUrl': 'https://go.aff.example/c?u=SKU9',
        'storeUrl': 'https://go.aff.example/c?u=SKU9',
      });
      expect(imported.storeId, 'store_1');
      expect(imported.externalProductId, 'SKU9');
      expect(imported.source, 'affiliate');
      expect(imported.commissionRate, 12);
      expect(imported.isActive, false);
    });

    test('"Shop Now" (offerFor) prefers affiliateUrl over a plain storeUrl', () {
      final p = ProductModel.fromJson({
        'id': 'p2',
        'name': 'X',
        'storeUrl': 'https://merchant.example/p/2',
        'affiliateUrl': 'https://go.aff.example/c?u=2',
      });
      expect(p.offerFor(null).storeUrl, 'https://go.aff.example/c?u=2');
    });

    test('country offer affiliate URL still wins when present', () {
      final p = ProductModel.fromJson({
        'id': 'p3',
        'name': 'X',
        'affiliateUrl': 'https://go.aff.example/global',
        'countryOffers': {
          'EG': {
            'price': 500,
            'currency': 'EGP',
            'affiliateUrl': 'https://go.aff.example/eg',
            'inStock': true,
          },
        },
      });
      expect(p.offerFor('EG').storeUrl, 'https://go.aff.example/eg');
      expect(p.offerFor(null).storeUrl, 'https://go.aff.example/global');
    });
  });
}
