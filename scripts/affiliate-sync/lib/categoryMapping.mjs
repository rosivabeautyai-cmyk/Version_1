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

  for (const doc of mappingDocs) {
    if (!doc || typeof doc.sourceCategory !== "string") continue;
    const target = normalizeCategory(doc.rosivaCategory);
    if (!target) continue;
    const key = doc.sourceCategory.trim().toLowerCase();
    if (!key) continue;
    if (doc.storeId) {
      if (!perStore.has(doc.storeId)) perStore.set(doc.storeId, new Map());
      perStore.get(doc.storeId).set(key, target);
    } else {
      global.set(key, target);
    }
  }

  return function resolveCategory(sourceCategory, storeId) {
    const raw = (sourceCategory ?? "").toString().trim().toLowerCase();
    if (raw) {
      if (storeId && perStore.has(storeId)) {
        const hit = perStore.get(storeId).get(raw);
        if (hit) return hit;
      }
      const g = global.get(raw);
      if (g) return g;
      // Also allow a mapping key to be a substring of a longer path
      // (e.g. mapping "fragrance" matches "Beauty > Fragrance > EDP").
      for (const [k, v] of global) {
        if (raw.includes(k)) return v;
      }
    }
    // Fall back to the keyword normalizer on the raw string.
    return normalizeCategory(sourceCategory);
  };
}
