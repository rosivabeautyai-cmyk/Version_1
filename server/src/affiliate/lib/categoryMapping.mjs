/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Category normalization for imported products.
 *
 * ROSIVA has exactly three canonical categories. External stores use
 * their own taxonomies, so every imported product's raw category is
 * resolved to one of these three (or dropped) via, in order:
 *
 *   1. an explicit, admin-configurable mapping row
 *      (`categoryMappings` collection) — store-specific first, then global
 *   2. the built-in keyword normalizer (mirrors
 *      lib/Feature/products/data/models/category_model.dart `normalizeCategory`)
 *
 * This mirrors the Dart `normalizeCategory` intentionally so the app
 * and the sync never disagree about what "makeup" means.
 */

export const ROSIVA_CATEGORIES = Object.freeze(["skincare", "makeup", "perfume"]);

/**
 * Port of the Dart `normalizeCategory`. Any raw category-ish string ->
 * one of ROSIVA's three canonical slugs, or null.
 * @param {string|null|undefined} raw
 * @return {string|null}
 */
export function normalizeCategory(raw) {
  if (raw == null) return null;
  const value = String(raw).trim().toLowerCase().replace(/[-_]+/g, " ");
  if (!value) return null;

  if (ROSIVA_CATEGORIES.includes(value)) return value;

  if (
    value.includes("makeup") ||
    value.includes("make up") ||
    value.includes("cosmetic")
  ) {
    return "makeup";
  }
  if (value.includes("skincare") || value.includes("skin care")) {
    return "skincare";
  }
  if (
    value.includes("perfume") ||
    value.includes("fragrance") ||
    value.includes("parfum") ||
    value.includes("cologne")
  ) {
    return "perfume";
  }
  return null;
}

/**
 * Built-in beauty vocabulary for the GENERALIZED sync only (not the
 * Dart mirror, not the Awin pipeline). These are the "base list" the
 * product owner approved. `categoryMappings` rows in Firestore are
 * layered on top by `buildCategoryResolver` so the list can be
 * extended later WITHOUT a code change. Longest term wins on a
 * substring match.
 */
export const BUILTIN_CATEGORY_TERMS = Object.freeze({
  skincare: [
    "serum", "moisturizer", "moisturiser", "cleanser", "toner",
    "face cream", "night cream", "day cream", "eye cream", "eye contour",
    "face wash", "face mask", "sheet mask", "face oil", "facial oil",
    "essence", "ampoule", "exfoliant", "exfoliator", "face scrub",
    "micellar", "sunscreen", "sunblock", "spf", "retinol", "hyaluronic",
    "niacinamide", "peeling", "anti-aging", "anti-ageing", "skin care",
  ],
  makeup: [
    "lipstick", "lip gloss", "lip liner", "lip tint", "lip stain",
    "lip balm", "foundation", "concealer", "mascara", "eyeliner",
    "eye liner", "eyeshadow", "eye shadow", "blush", "bronzer",
    "highlighter", "contour", "face primer", "makeup primer",
    "setting spray", "setting powder", "loose powder", "pressed powder",
    "bb cream", "cc cream", "tinted moisturizer", "brow", "eyebrow",
    "nail polish", "nail lacquer", "kohl", "makeup palette",
    "eyeshadow palette", "make up", "make-up",
  ],
  perfume: [
    "perfume", "fragrance", "eau de parfum", "eau de toilette",
    "eau de cologne", "parfum", "edp", "edt", "attar", "oud",
    "perfume oil",
  ],
});

/**
 * Builds a fast lookup from a list of `categoryMappings` documents.
 * Each doc: { storeId?: string|null, sourceCategory: string, rosivaCategory: string }
 *
 * A row with no `storeId` (or storeId === null) is a global mapping.
 * Store-specific rows win over global rows for the same sourceCategory.
 *
 * @param {Array<object>} mappingDocs
 * @return {(sourceCategory: string, storeId?: string) => (string|null)}
 */
export function buildCategoryResolver(mappingDocs = []) {
  const global = new Map();
  const perStore = new Map(); // storeId -> Map(sourceKey -> rosivaCategory)

  // Keys and lookups are compared with hyphens/underscores flattened to
  // spaces (same as `normalizeCategory`), so "anti-aging" in a feed
  // matches the "anti aging" term and vice-versa.
  const normKey = (s) => String(s).trim().toLowerCase().replace(/[-_]+/g, " ");

  // Base list (code). Firestore rows below are layered on top and win
  // on an exact-key match, so an admin can override a builtin.
  for (const [cat, terms] of Object.entries(BUILTIN_CATEGORY_TERMS)) {
    for (const term of terms) global.set(normKey(term), cat);
  }

  for (const doc of mappingDocs) {
    if (!doc || typeof doc.sourceCategory !== "string") continue;
    const target = normalizeCategory(doc.rosivaCategory);
    if (!target) continue;
    const key = normKey(doc.sourceCategory);
    if (!key) continue;
    if (doc.storeId) {
      if (!perStore.has(doc.storeId)) perStore.set(doc.storeId, new Map());
      perStore.get(doc.storeId).set(key, target);
    } else {
      global.set(key, target);
    }
  }

  // Substring scans run longest-key-first so a specific compound term
  // wins over a generic one it contains — e.g. "tinted moisturizer"
  // (-> makeup) must beat "moisturizer" (-> skincare), and
  // "eau de parfum" must beat "parfum".
  const byLenDesc = (m) =>
    [...m.entries()].sort((a, b) => b[0].length - a[0].length);
  const globalSorted = byLenDesc(global);
  const perStoreSorted = new Map(
    [...perStore.entries()].map(([sid, m]) => [sid, byLenDesc(m)]),
  );

  return function resolveCategory(sourceCategory, storeId) {
    const raw = normKey(sourceCategory ?? "");
    if (raw) {
      if (storeId && perStore.has(storeId)) {
        const exact = perStore.get(storeId).get(raw);
        if (exact) return exact;
        for (const [k, v] of perStoreSorted.get(storeId)) {
          if (raw.includes(k)) return v;
        }
      }
      const g = global.get(raw);
      if (g) return g;
      for (const [k, v] of globalSorted) {
        if (raw.includes(k)) return v;
      }
    }
    // Fall back to the keyword normalizer on the raw string.
    return normalizeCategory(sourceCategory);
  };
}
