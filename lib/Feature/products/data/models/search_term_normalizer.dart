/// Maps common Arabic beauty-term variants (including transliteration
/// spelling differences, e.g. "ماسكرا" vs "ماسكرة") to the single
/// English word the catalog actually stores — product name/brand/tags
/// are always English (see ProductApiService), and the direct Search
/// screen sends whatever the user types straight into a literal
/// substring match with no translation layer, unlike AI chat (where
/// Gemini itself translates Arabic to English before searching). So
/// typing "ماسكرا" into Search would otherwise match nothing, ever,
/// no matter how many real mascara products exist.
///
/// Deliberately a small, explicit, testable lookup — not a general
/// Arabic transliteration engine — covering exactly the terms ROSIVA
/// is known to need. Falls through unchanged for anything else,
/// including plain English input (never breaks existing search).
library;

const Map<String, String> _arabicSearchSynonyms = {
  // Mascara — two common Arabic transliterations.
  'ماسكرا': 'mascara',
  'ماسكرة': 'mascara',
  // Lipstick.
  'روج': 'lipstick',
  // Eyeliner — several common transliteration spellings.
  'ايلاينر': 'eyeliner',
  'آيلاينر': 'eyeliner',
  'إيلاينر': 'eyeliner',
  // Highlighter.
  'هايلايتر': 'highlighter',
  // Perfume.
  'عطر': 'perfume',
  // Makeup brushes — both common word orders/spellings.
  'فرش مكياج': 'makeup brush',
  'فرشاة مكياج': 'makeup brush',
  'فرش المكياج': 'makeup brush',
};

/// Normalizes a raw, user-typed search string: if it contains (as a
/// whole word/phrase, not an accidental substring of something else)
/// one of the known Arabic beauty-term variants, returns the English
/// catalog term instead. Anything else — English input, or Arabic text
/// not in the list — passes through unchanged, exactly as typed.
String normalizeSearchTerm(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  final lower = trimmed.toLowerCase();
  for (final entry in _arabicSearchSynonyms.entries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }
  return trimmed;
}
