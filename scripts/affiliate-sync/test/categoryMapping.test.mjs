import test from "node:test";
import assert from "node:assert/strict";

import { normalizeCategory, buildCategoryResolver } from "../lib/categoryMapping.mjs";

test("normalizeCategory: canonical + synonyms + null", () => {
  assert.equal(normalizeCategory("skincare"), "skincare");
  assert.equal(normalizeCategory("Skin Care"), "skincare");
  assert.equal(normalizeCategory("Face Care"), null); // not a keyword match on its own
  assert.equal(normalizeCategory("Foundation"), null);
  assert.equal(normalizeCategory("MAKEUP"), "makeup");
  assert.equal(normalizeCategory("make-up"), "makeup");
  assert.equal(normalizeCategory("cosmetics"), "makeup");
  assert.equal(normalizeCategory("Eau de Parfum"), "perfume");
  assert.equal(normalizeCategory("fragrance"), "perfume");
  assert.equal(normalizeCategory("garden hose"), null);
  assert.equal(normalizeCategory(null), null);
  assert.equal(normalizeCategory(""), null);
});

test("resolver: explicit mapping rows beat the keyword fallback", () => {
  const resolve = buildCategoryResolver([
    { sourceCategory: "Face Care", rosivaCategory: "skincare" },
    { sourceCategory: "Foundation", rosivaCategory: "makeup" },
    { sourceCategory: "Eau de Toilette", rosivaCategory: "perfume" },
  ]);
  assert.equal(resolve("Face Care"), "skincare");
  assert.equal(resolve("foundation"), "makeup");
  assert.equal(resolve("Eau de Toilette"), "perfume");
});

test("resolver: store-specific mapping wins over global", () => {
  const resolve = buildCategoryResolver([
    { sourceCategory: "beauty", rosivaCategory: "makeup" },
    { storeId: "store_1", sourceCategory: "beauty", rosivaCategory: "skincare" },
  ]);
  assert.equal(resolve("beauty", "store_1"), "skincare");
  assert.equal(resolve("beauty", "store_2"), "makeup");
});

test("resolver: substring match on a category path", () => {
  const resolve = buildCategoryResolver([{ sourceCategory: "fragrance", rosivaCategory: "perfume" }]);
  assert.equal(resolve("Beauty > Fragrance > For Her"), "perfume");
});

test("resolver: unknown category still falls through to keyword normalizer", () => {
  const resolve = buildCategoryResolver([]);
  assert.equal(resolve("Skin care serums"), "skincare");
  assert.equal(resolve("random hardware"), null);
});

test("resolver: built-in beauty vocabulary resolves without any Firestore rows", () => {
  const resolve = buildCategoryResolver([]);
  assert.equal(resolve("Serums"), "skincare");
  assert.equal(resolve("Moisturizers"), "skincare");
  assert.equal(resolve("Foundation"), "makeup");
  assert.equal(resolve("Lipstick"), "makeup");
  assert.equal(resolve("Mascara"), "makeup");
  assert.equal(resolve("Eau de Toilette"), "perfume");
  // name fallback style input
  assert.equal(resolve("Vitamin C Face Serum"), "skincare");
  // genuinely out of scope
  assert.equal(resolve("Body Lotion"), null);
  assert.equal(resolve("Shampoo & Conditioner"), null);
});

test("resolver: longest term wins on a substring match", () => {
  const resolve = buildCategoryResolver([]);
  // "tinted moisturizer" (makeup) must beat "moisturizer" (skincare)
  assert.equal(resolve("Tinted Moisturizer"), "makeup");
  // "eau de parfum" (perfume) contains "parfum" (also perfume) — same result, but exercises ordering
  assert.equal(resolve("Eau de Parfum Intense"), "perfume");
  // hyphen / underscore normalization
  assert.equal(resolve("anti-aging"), "skincare");
});

test("resolver: a Firestore row can override a built-in", () => {
  const resolve = buildCategoryResolver([
    { sourceCategory: "lip balm", rosivaCategory: "skincare" }, // builtin says makeup
  ]);
  assert.equal(resolve("Lip Balm"), "skincare");
});
