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
 * If any of these substrings appear in a row's *category* fields
 * (merchant-assigned taxonomy, not the product name/description), the
 * product is skipped outright — checked before the allow-list below.
 *
 * Kept deliberately specific (e.g. "vitamin supplement" rather than
 * bare "vitamin", "baby diaper" rather than bare "baby") so this
 * doesn't reject real beauty products that happen to share a word
 * with an unrelated category — "Vitamin C Serum" and "Baby Lips Lip
 * Balm" are real product lines that a bare "vitamin"/"baby" match
 * used to wrongly skip.
 */
export const DENY_KEYWORDS = [
  "toothbrush", "toothpaste", "mouthwash", "dental floss", "oral care",
  "multivitamin", "vitamin supplement", "vitamin tablet", "vitamin capsule",
  "dietary supplement", "protein powder", "supplement",
  "grocery", "snack food", "soft drink", "beverage",
  "smartphone", "laptop", "desktop computer", "digital camera",
  "headphone", "bluetooth speaker", "electronics accessory", "gadget",
  "sex toy", "vibrator", "intimate", "condom", "lubricant gel",
  "adult toy", "erotic",
  "living room furniture", "kitchen appliance", "children's toy",
  "pet supplies", "car accessory", "power tool", "automotive",
  "baby diaper", "infant formula",
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
      "body lotion", "body wash", "body butter", "hand cream",
      "hyaluronic", "retinol", "niacinamide", "collagen", "micellar",
      "acne", "blemish", "hydrating", "day cream", "night cream",
      "toiletries", "toiletry", "lip balm", "lip care", "skin treatment",
    ],
  },
  {
    category: "makeup",
    keywords: [
      "makeup", "make-up", "make up", "cosmetic", "lipstick",
      "lip gloss", "foundation", "mascara", "eyeshadow", "eye shadow",
      "eyeliner", "eye liner", "blush", "concealer", "nail polish",
      "nail varnish", "bronzer", "highlighter", "primer",
      "setting spray", "lip liner", "contour", "eyebrow", "brow",
      "lash", "false lashes", "kohl", "compact powder", "beauty palette",
      "makeup remover", "makeup brush", "brush set", "makeup palette",
    ],
  },
  {
    category: "perfume",
    keywords: [
      "perfume", "fragrance", "eau de parfum", "eau de toilette",
      "eau de cologne", "cologne", "parfum", "scent", "body spray",
      "body mist", "eau de", "aftershave", "fragrance gift set",
      "edp", "edt",
    ],
  },
];

/**
 * Classifies a product into a ROSIVA category, or returns null if it
 * should be skipped (either its category fields hit the deny-list, or
 * nothing about it — category fields, name, brand, description, or
 * tags — matched an allow-list rule).
 *
 * Deny-listing only looks at the merchant's own category taxonomy
 * (`categoryFields`), never the product name/description — those are
 * marketing copy and can innocently contain a deny word (e.g. "Baby
 * Lips" in a product name) without the product actually being in a
 * denied category. Allow-listing is intentionally broader: it also
 * looks at the product's own name/brand/description/tags, since Awin
 * merchant category text is inconsistent and often misses genuine
 * skincare/makeup/perfume products that this catches instead.
 *
 * @param {object} product
 * @param {string} [product.categoryName] Awin `category_name`.
 * @param {string} [product.merchantCategory] Awin `merchant_category`.
 * @param {string} [product.merchantCategoryPath] Awin
 *   `merchant_product_category_path`.
 * @param {string} [product.productName] Awin `product_name`.
 * @param {string} [product.brandName] Awin `brand_name`.
 * @param {string} [product.description] Awin `description`.
 * @param {string} [product.keywords] Awin `keywords`.
 * @return {string | null} The matched ROSIVA category, or null if the
 *   product should be skipped.
 */
export function classifyCategory({
  categoryName,
  merchantCategory,
  merchantCategoryPath,
  productName,
  brandName,
  description,
  keywords,
} = {}) {
  const categoryHaystack = [categoryName, merchantCategory, merchantCategoryPath]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (DENY_KEYWORDS.some((keyword) => categoryHaystack.includes(keyword))) {
    return null;
  }

  const fullHaystack = [
    categoryHaystack,
    productName,
    brandName,
    description,
    keywords,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (!fullHaystack) return null;

  for (const rule of CATEGORY_RULES) {
    if (rule.keywords.some((keyword) => fullHaystack.includes(keyword))) {
      return rule.category;
    }
  }

  return null;
}
