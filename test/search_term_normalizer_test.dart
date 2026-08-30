// STEP 5 of the ROSIVA audit: the direct Search screen sends whatever
// the user types straight into a literal English-only substring
// match (see SearchProvider._search / ProductApiService.fetchProducts)
// — unlike AI chat, where Gemini translates Arabic to English before
// searching. Without normalizeSearchTerm, typing "ماسكرا" would match
// zero products even though real mascara products exist, since the
// catalog itself is English-only. These tests prove the fix for
// exactly the terms requested: مسكرا/mascara, روج/lipstick,
// ايلاينر/eyeliner, هايلايتر/highlighter, عطر/perfume, فرش
// مكياج/makeup brushes.
import 'package:flutter_test/flutter_test.dart';

import 'package:rosivia/Feature/products/data/models/search_term_normalizer.dart';

void main() {
  group('normalizeSearchTerm — Arabic beauty-term variants', () {
    test('ماسكرا -> mascara', () {
      expect(normalizeSearchTerm('ماسكرا'), 'mascara');
    });

    test('ماسكرة (alternate transliteration) -> mascara', () {
      expect(normalizeSearchTerm('ماسكرة'), 'mascara');
    });

    test('mascara (already English) stays mascara', () {
      expect(normalizeSearchTerm('mascara'), 'mascara');
    });

    test('روج -> lipstick', () {
      expect(normalizeSearchTerm('روج'), 'lipstick');
    });

    test('ايلاينر -> eyeliner', () {
      expect(normalizeSearchTerm('ايلاينر'), 'eyeliner');
    });

    test('آيلاينر (alef-madda variant) -> eyeliner', () {
      expect(normalizeSearchTerm('آيلاينر'), 'eyeliner');
    });

    test('هايلايتر -> highlighter', () {
      expect(normalizeSearchTerm('هايلايتر'), 'highlighter');
    });

    test('عطر -> perfume', () {
      expect(normalizeSearchTerm('عطر'), 'perfume');
    });

    test('فرش مكياج -> makeup brush', () {
      expect(normalizeSearchTerm('فرش مكياج'), 'makeup brush');
    });

    test('فرشاة مكياج (alternate word form) -> makeup brush', () {
      expect(normalizeSearchTerm('فرشاة مكياج'), 'makeup brush');
    });

    test('leading/trailing whitespace is trimmed either way', () {
      expect(normalizeSearchTerm('  ماسكرا  '), 'mascara');
    });

    test('unrecognized Arabic text passes through unchanged', () {
      expect(normalizeSearchTerm('كريم غريب'), 'كريم غريب');
    });

    test('plain English input never regresses', () {
      expect(normalizeSearchTerm('foundation'), 'foundation');
    });

    test('empty input stays empty', () {
      expect(normalizeSearchTerm(''), '');
      expect(normalizeSearchTerm('   '), '');
    });
  });
}
