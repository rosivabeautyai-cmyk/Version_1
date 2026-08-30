// Pass 2 regression tests — pure logic + a focused ProductPriceText
// widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rosivia/Feature/admin/data/models/admin_product_query.dart';
import 'package:rosivia/Feature/products/data/models/country_offer_model.dart';
import 'package:rosivia/Feature/products/data/models/product_model.dart';
import 'package:rosivia/Feature/products/presentation/widgets/product_price_text.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';

ProductModel _p(Map<String, dynamic> extra) => ProductModel.fromJson({
      'id': 'p',
      'name': 'P',
      'price': 30.0,
      'currency': 'USD',
      'storeUrl': 'https://default',
      'rosivaCategory': 'makeup',
      'isRosivaProduct': true,
      'gender': 'women',
      ...extra,
    });

void main() {
  group('Country offers — offerFor', () {
    final product = _p({
      'countryOffers': {
        'EG': {
          'price': 1500,
          'currency': 'EGP',
          'affiliateUrl': 'https://eg',
          'inStock': true,
        },
        'US': {
          'price': 35,
          'currency': 'USD',
          'affiliateUrl': 'https://us',
          'inStock': false,
        },
      },
    });

    test('EG offer returned for EG', () {
      final o = product.offerFor('eg');
      expect(o.price, 1500);
      expect(o.currency, 'EGP');
      expect(o.storeUrl, 'https://eg');
      expect(o.inStock, true);
    });

    test('US offer returned for US', () {
      final o = product.offerFor('US');
      expect(o.price, 35);
      expect(o.currency, 'USD');
      expect(o.storeUrl, 'https://us');
      expect(o.inStock, false);
    });

    test('missing offer falls back to default product', () {
      final o = product.offerFor('SA');
      expect(o.price, 30.0);
      expect(o.currency, 'USD');
      expect(o.storeUrl, 'https://default');
    });

    test('no country selected falls back to default', () {
      final o = product.offerFor(null);
      expect(o.price, 30.0);
      expect(o.storeUrl, 'https://default');
    });
  });

  group('CountryOffer.mapFromJson', () {
    test('parses a well-formed map', () {
      final m = CountryOffer.mapFromJson({
        'EG': {'price': 10, 'currency': 'egp', 'affiliateUrl': 'https://x'},
      });
      expect(m['EG']!.price, 10);
      expect(m['EG']!.currency, 'EGP'); // upper-cased
      expect(m['EG']!.inStock, true); // default
    });

    test('malformed input is ignored, not thrown', () {
      expect(CountryOffer.mapFromJson('nope'), isEmpty);
      expect(CountryOffer.mapFromJson(null), isEmpty);
      expect(CountryOffer.mapFromJson({'EG': 'not-a-map'}), isEmpty);
    });
  });

  group('Country visibility — isAvailableIn', () {
    test('product with NO country offers is visible everywhere', () {
      final p = _p({});
      expect(p.isAvailableIn('EG'), true);
      expect(p.isAvailableIn('US'), true);
      expect(p.isAvailableIn(null), true);
    });

    test('product WITH an EG offer appears in EG, not where it has no offer', () {
      final p = _p({
        'countryOffers': {
          'EG': {'price': 1, 'currency': 'EGP'},
        },
      });
      expect(p.isAvailableIn('EG'), true);
      expect(p.isAvailableIn('US'), false);
      expect(p.isAvailableIn(null), true); // no country selected -> visible
    });
  });

  group('AdminProductQuery.matches — Pass 2 filters', () {
    ProductModel prod(Map<String, dynamic> extra) => _p(extra);

    test('country: only products with an offer for that country', () {
      const q = AdminProductQuery(country: 'EG');
      expect(
        q.matches(prod({
          'countryOffers': {
            'EG': {'price': 1, 'currency': 'EGP'},
          }
        })),
        true,
      );
      expect(q.matches(prod({})), false);
    });

    test('hasCountryOffer / missingCountryOffer', () {
      final withOffer = prod({
        'countryOffers': {
          'EG': {'price': 1, 'currency': 'EGP'},
        }
      });
      final without = prod({});
      expect(const AdminProductQuery(hasCountryOffer: true).matches(withOffer), true);
      expect(const AdminProductQuery(hasCountryOffer: true).matches(without), false);
      expect(const AdminProductQuery(missingCountryOffer: true).matches(without), true);
      expect(
          const AdminProductQuery(missingCountryOffer: true).matches(withOffer), false);
    });

    test('currency matches effective OR any offer currency', () {
      final p = prod({
        'currency': 'USD',
        'countryOffers': {
          'EG': {'price': 1, 'currency': 'EGP'},
        }
      });
      expect(const AdminProductQuery(currency: 'USD').matches(p), true);
      expect(const AdminProductQuery(currency: 'EGP').matches(p), true);
      expect(const AdminProductQuery(currency: 'GBP').matches(p), false);
    });

    test('inStockOnly / outOfStockOnly use the country offer when a country is set', () {
      final p = prod({
        'active': true,
        'inStock': true,
        'countryOffers': {
          'EG': {'price': 1, 'currency': 'EGP', 'inStock': false},
        }
      });
      expect(
        const AdminProductQuery(country: 'EG', outOfStockOnly: true).matches(p),
        true,
      );
      expect(
        const AdminProductQuery(country: 'EG', inStockOnly: true).matches(p),
        false,
      );
    });
  });

  group('ProductPriceText widget', () {
    Future<void> pump(
      WidgetTester tester,
      ProductModel product, {
      required String? country,
    }) async {
      SharedPreferences.setMockInitialValues(
        country == null ? {} : {'regional_country': country},
      );
      final regional = RegionalPrefsProvider();
      await regional.load(); // Firestore call fails silently -> fallbacks
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<RegionalPrefsProvider>.value(
            value: regional,
            child: Scaffold(body: ProductPriceText(product: product)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a real country offer price is shown verbatim, never converted',
        (tester) async {
      final product = _p({
        'countryOffers': {
          'EG': {'price': 1500, 'currency': 'EGP', 'affiliateUrl': 'https://x'},
        },
      });
      await pump(tester, product, country: 'EG');
      // EGP symbol suffix format, no "≈" estimate line for a real offer.
      expect(find.textContaining('1,500'), findsOneWidget);
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('no country offer + no rate -> just the listed price, no guess',
        (tester) async {
      final product = _p({}); // USD 30, no offers
      await pump(tester, product, country: 'EG');
      // currencies collection is unavailable in the test -> no rate ->
      // no approximate line.
      expect(find.textContaining('≈'), findsNothing);
      expect(find.textContaining('30'), findsOneWidget);
    });
  });
}
