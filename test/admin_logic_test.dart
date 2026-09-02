// Unit tests for the Pass-1 Admin foundation logic that is pure and
// Firestore-free:
//   * ProductModel adminOverrides layering + offerFor() + featured/
//     active fallbacks
//   * AdminProductQuery.matches (the client-side admin filters)
//   * CurrencyService formatting / conversion / approx
import 'package:flutter_test/flutter_test.dart';

import 'package:rosivia/Feature/admin/data/models/admin_product_query.dart';
import 'package:rosivia/Feature/admin/data/models/currency_config_model.dart';
import 'package:rosivia/Feature/products/data/models/product_model.dart';
import 'package:rosivia/core/services/currency_service.dart';

void main() {
  group('ProductModel.adminOverrides', () {
    test('overrides layer over sync-owned display fields', () {
      final p = ProductModel.fromJson({
        'id': 'p1',
        'name': 'Awin Name',
        'brand': 'Awin Brand',
        'price': 20.0,
        'currency': 'GBP',
        'storeUrl': 'https://awin/deep',
        'rosivaCategory': 'makeup',
        'isRosivaProduct': true,
        'gender': 'women',
        'adminOverrides': {
          'name': 'Corrected Name',
          'price': 14.99,
          'currency': 'USD',
          'storeUrl': 'https://merchant/fixed',
        },
      });
      expect(p.name, 'Corrected Name');
      expect(p.price, 14.99);
      expect(p.currency, 'USD');
      expect(p.storeUrl, 'https://merchant/fixed');
      // Brand not overridden -> sync value kept.
      expect(p.brand, 'Awin Brand');
    });

    test('overrides can NOT change category / eligibility / gender', () {
      final p = ProductModel.fromJson({
        'id': 'p2',
        'name': 'x',
        'rosivaCategory': 'makeup',
        'isRosivaProduct': true,
        'gender': 'women',
        'adminOverrides': {
          'rosivaCategory': 'perfume',
          'category': 'perfume',
          'isRosivaProduct': false,
          'gender': 'men',
        },
      });
      expect(p.category, 'makeup');
      expect(p.isRosivaProduct, true);
      expect(p.gender, 'women');
    });

    test('featured / active fall back to legacy isEditorsChoice / inStock', () {
      final legacy = ProductModel.fromJson({
        'id': 'a',
        'name': 'a',
        'isEditorsChoice': true,
        'inStock': false,
      });
      expect(legacy.featured, true);
      expect(legacy.active, false);

      final explicit = ProductModel.fromJson({
        'id': 'b',
        'name': 'b',
        'isEditorsChoice': true,
        'inStock': true,
        'featured': false,
        'active': false,
      });
      expect(explicit.featured, false);
      expect(explicit.active, false);
    });

    test('offerFor returns the country offer when present, default otherwise', () {
      final p = ProductModel.fromJson({
        'id': 'c',
        'name': 'c',
        'price': 30.0,
        'currency': 'USD',
        'storeUrl': 'https://default',
        'countryOffers': {
          'EG': {
            'price': 1450,
            'currency': 'EGP',
            'affiliateUrl': 'https://eg-store',
            'inStock': true,
          },
        },
      });
      final eg = p.offerFor('eg');
      expect(eg.price, 1450);
      expect(eg.currency, 'EGP');
      expect(eg.storeUrl, 'https://eg-store');

      final us = p.offerFor('US');
      expect(us.price, 30.0);
      expect(us.currency, 'USD');
      expect(us.storeUrl, 'https://default');

      final none = p.offerFor(null);
      expect(none.price, 30.0);
    });
  });

  group('AdminProductQuery.matches', () {
    ProductModel prod({
      String name = 'Test',
      String? brand,
      bool featured = false,
      bool active = true,
      bool eligible = true,
      double? price = 9.99,
      String? storeUrl = 'https://x',
    }) {
      return ProductModel.fromJson({
        'id': name,
        'name': name,
        'brand': brand,
        'featured': featured,
        'active': active,
        'isRosivaProduct': eligible,
        'price': price,
        'storeUrl': storeUrl,
        'rosivaCategory': 'makeup',
        'gender': 'women',
      });
    }

    test('onlyFeatured', () {
      const q = AdminProductQuery(onlyFeatured: true);
      expect(q.matches(prod(featured: true)), true);
      expect(q.matches(prod(featured: false)), false);
    });

    test('onlyInactive', () {
      const q = AdminProductQuery(onlyInactive: true);
      expect(q.matches(prod(active: false)), true);
      expect(q.matches(prod(active: true)), false);
    });

    test('onlyIneligible', () {
      const q = AdminProductQuery(onlyIneligible: true);
      expect(q.matches(prod(eligible: false)), true);
      expect(q.matches(prod(eligible: true)), false);
    });

    test('missingPrice', () {
      const q = AdminProductQuery(missingPrice: true);
      expect(q.matches(prod(price: null)), true);
      expect(q.matches(prod(price: 5)), false);
    });

    test('missingAffiliate (no default url and no country offer url)', () {
      const q = AdminProductQuery(missingAffiliate: true);
      expect(q.matches(prod(storeUrl: null)), true);
      expect(q.matches(prod(storeUrl: '')), true);
      expect(q.matches(prod(storeUrl: 'https://x')), false);
    });

    test('search matches name / brand', () {
      const q = AdminProductQuery(search: 'dior');
      expect(q.matches(prod(name: 'Dior Mascara')), true);
      expect(q.matches(prod(name: 'X', brand: 'Dior')), true);
      expect(q.matches(prod(name: 'X', brand: 'NYX')), false);
    });
  });

  group('CurrencyService', () {
    final clock = DateTime(2026, 6, 1, 12);
    final fresh = clock.subtract(const Duration(days: 1));
    final stale = clock.subtract(const Duration(days: 30));
    final svc = CurrencyService(
      now: () => clock,
      currencies: {
        'USD': CurrencyConfig(
            code: 'USD', symbol: r'$', nameEn: 'US Dollar', nameAr: '',
            rateToUsd: 1, rateUpdatedAt: fresh),
        'EGP': CurrencyConfig(
            code: 'EGP', symbol: 'ج.م', nameEn: 'Egyptian Pound', nameAr: '',
            rateToUsd: 0.02, rateUpdatedAt: fresh),
        'GBP': const CurrencyConfig(
            code: 'GBP', symbol: '£', nameEn: 'Pound', nameAr: '', rateToUsd: null),
        'SAR': CurrencyConfig(
            code: 'SAR', symbol: 'ر.س', nameEn: 'Riyal', nameAr: '',
            rateToUsd: 0.27, rateUpdatedAt: stale),
      },
    );

    test('format: prefix symbol for USD/GBP/EUR, suffix otherwise', () {
      expect(svc.format(25, 'USD'), r'$25.00');
      expect(svc.format(1300, 'EGP'), '1,300.00 ج.م');
    });

    test('format falls back to a built-in symbol for unknown config', () {
      final bare = CurrencyService();
      expect(bare.format(10, 'SAR'), '10.00 ر.س');
      expect(bare.format(10, 'ZZZ'), '10.00 ZZZ');
    });

    test('convert: uses rateToUsd both ways; null when a rate is missing', () {
      expect(svc.convert(1, 'USD', 'EGP'), closeTo(50, 0.001)); // 1 / 0.02
      expect(svc.convert(100, 'EGP', 'USD'), closeTo(2, 0.001)); // 100 * 0.02
      expect(svc.convert(5, 'USD', 'GBP'), isNull); // GBP has no rate
      expect(svc.convert(5, 'USD', 'USD'), 5); // same currency
    });

    test('convert: a stale rate (> 7 days) is treated as absent', () {
      expect(svc.convert(10, 'USD', 'SAR'), isNull);
      expect(svc.convert(10, 'SAR', 'USD'), isNull);
      expect(svc.approx(10, 'USD', 'SAR'), isNull);
    });

    test('approx: "≈ N CODE" or null', () {
      expect(svc.approx(25, 'USD', 'EGP'), '≈ 1,250 EGP');
      expect(svc.approx(25, 'USD', 'GBP'), isNull);
      expect(svc.approx(25, 'USD', 'USD'), isNull);
    });
  });
}
