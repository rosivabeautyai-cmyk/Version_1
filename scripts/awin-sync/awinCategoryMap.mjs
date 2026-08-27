/**
 * ROSIVA product-category filtering strategy for the Awin feed sync.
 *
 * ROSIVA only imports Skincare / Makeup / Perfume products. Everything
 * else (electronics, food, toothbrushes, intimate/sexual wellness,
 * etc.) is skipped during sync. This file is the single place to
 * adjust that behavior — add/remove keywords here, nothing else in
 * the sync pipeline needs to change.
 *
 * Ported 1:1 from the original functions/src/awinCategoryMap.ts
 * (same rules, same keywords) when the sync moved from a Firebase
 * Cloud Function to this standalone GitHub Actions script.
 */

export const ROSIVA_CATEGORIES = ["skincare", "makeup", "perfume"];

/**
 * If any of these substrings appear in a row's category fields, the
 * product is skipped outright — checked before the allow-list below.
 */
export const DENY_KEYWORDS = [
  "toothbrush", "toothpaste", "dental", "oral care",
  "vitamin", "supplement", "food", "grocery", "snack", "drink",
  "electronics", "phone", "laptop", "computer", "camera",
  "headphone", "gadget",
  "sex toy", "vibrator", "intimate", "condom", "lubricant",
  "adult", "erotic",
  "furniture", "kitchen", "toy", "pet supplies", "automotive", "tool",
  "baby", "diaper",
];

/**
 * Ordered list of (category -> keywords) rules. The first rule whose
 * keywords match wins. Add new keywords/rules here as the real Awin
 * category taxonomy is observed in production data.
 */
export const CATEGORY_RULES = [
  {
    category: "skincare",
    keywords: [
      "skincare", "skin care", "moisturi", "cleanser", "serum",
      "sunscreen", "spf", "toner", "exfoliat", "face cream", "facial",
      "eye cream", "face mask", "anti-aging", "anti aging",
      "body lotion", "body wash",
    ],
  },
  {
    category: "makeup",
    keywords: [
      "makeup", "make-up", "make up", "cosmetic", "lipstick",
      "lip gloss", "foundation", "mascara", "eyeshadow", "eye shadow",
      "eyeliner", "eye liner", "blush", "concealer", "nail polish",
      "nail varnish", "bronzer", "highlighter", "primer",
      "setting spray", "lip liner",
    ],
  },
  {
    category: "perfume",
    keywords: [
      "perfume", "fragrance", "eau de parfum", "eau de toilette",
      "cologne", "parfum", "scent", "body spray", "body mist",
    ],
  },
];

/**
 * Classifies a row into a ROSIVA category using its Awin category
 * fields, or returns null if the product should be skipped (either it
 * matched the deny-list, or it matched no allow-list rule).
 * @param {...(string | undefined)} fields Category-ish text fields to
 *   inspect (category_name, merchant_category, etc).
 * @return {string | null} The matched ROSIVA category, or null if the
 *   product should be skipped.
 */
export function classifyCategory(...fields) {
  const haystack = fields.filter(Boolean).join(" ").toLowerCase();
  if (!haystack) return null;

  if (DENY_KEYWORDS.some((keyword) => haystack.includes(keyword))) {
    return null;
  }

  for (const rule of CATEGORY_RULES) {
    if (rule.keywords.some((keyword) => haystack.includes(keyword))) {
      return rule.category;
    }
  }

  return null;
}
