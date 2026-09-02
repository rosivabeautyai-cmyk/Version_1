import test from "node:test";
import assert from "node:assert/strict";

import { normalizeProduct, buildProductDocId } from "../lib/normalizer.mjs";
import { buildCategoryResolver } from "../lib/categoryMapping.mjs";
import { ERROR_CODES } from "../lib/errors.mjs";

const store = {
  id: "store_123",
  slug: "shein",
  currency: "USD",
  defaultCommissionRate: 8,
  commissionType: "percentage",
};
const resolveCategory = buildCategoryResolver([
  { sourceCategory: "Foundation", rosivaCategory: "makeup" },
]);

function raw(overrides = {}) {
  return {
    externalProductId: "SHEIN_987654",
    name: "Second Skin Foundation",
    description: "A lightweight foundation",
    brand: "Velvet",
    categoryName: "Foundation",
    price: "24.99",
    currency: "USD",
    imageUrl: "https://img.test/a.jpg",
    productUrl: "https://shein.test/p/987654",
    affiliateUrl: "https://go.aff.test/click?u=987654",
    availability: "in stock",
    ...overrides,
  };
}

test("doc id = storeId + externalProductId, never the name", () => {
  assert.equal(buildProductDocId("store_123", "SHEIN_987654"), "store_123:SHEIN_987654");
  const a = normalizeProduct({ raw: raw(), store, resolveCategory });
  assert.equal(a.docId, "store_123:SHEIN_987654");
});

test("two stores, same product name -> different ids (no collision)", () => {
  const s2 = { ...store, id: "store_999", slug: "other" };
  const a = normalizeProduct({ raw: raw(), store, resolveCategory });
  const b = normalizeProduct({ raw: raw(), store: s2, resolveCategory });
  assert.notEqual(a.docId, b.docId);
});

test("happy path: normalized doc shape", () => {
  const { ok, doc } = normalizeProduct({ raw: raw(), store, resolveCategory, nowIso: "2026-01-01T00:00:00.000Z" });
  assert.ok(ok);
  assert.equal(doc.storeId, "store_123");
  assert.equal(doc.externalProductId, "SHEIN_987654");
  assert.equal(doc.name, "Second Skin Foundation");
  assert.equal(doc.price, 24.99);
  assert.equal(doc.currency, "USD");
  assert.equal(doc.rosivaCategory, "makeup");
  assert.equal(doc.category, "makeup");
  assert.equal(doc.source, "affiliate");
  assert.equal(doc.isRosivaProduct, false); // affiliate imports excluded from AI catalog
  assert.equal(doc.availability, "in_stock");
  assert.equal(doc.affiliateUrl, "https://go.aff.test/click?u=987654");
  assert.equal(doc.storeUrl, "https://go.aff.test/click?u=987654"); // "Shop Now" keeps working
  assert.equal(doc.commissionRate, 8); // store default
  assert.equal(doc.lastSyncedAt, "2026-01-01T00:00:00.000Z");
});

test("missing id / name / url are rejected with specific codes", () => {
  assert.equal(
    normalizeProduct({ raw: raw({ externalProductId: "" }), store, resolveCategory }).code,
    ERROR_CODES.MISSING_PRODUCT_ID,
  );
  assert.equal(
    normalizeProduct({ raw: raw({ name: "  " }), store, resolveCategory }).code,
    ERROR_CODES.MISSING_PRODUCT_NAME,
  );
  assert.equal(
    normalizeProduct({ raw: raw({ productUrl: "", affiliateUrl: "" }), store, resolveCategory }).code,
    ERROR_CODES.MISSING_PRODUCT_URL,
  );
});

test("invalid price is rejected", () => {
  assert.equal(
    normalizeProduct({ raw: raw({ price: "abc" }), store, resolveCategory }).code,
    ERROR_CODES.INVALID_PRICE,
  );
  // absent price is allowed (nullable)
  assert.ok(normalizeProduct({ raw: raw({ price: undefined }), store, resolveCategory }).ok);
});

test("discountPercentage derived from oldPrice > price", () => {
  const { doc } = normalizeProduct({
    raw: raw({ price: 80, oldPrice: 100 }),
    store,
    resolveCategory,
  });
  assert.equal(doc.discountPercentage, 20);
});

test("classifier passthrough is honored when present", () => {
  const { doc } = normalizeProduct({
    raw: raw({
      rosivaClassification: {
        isRosivaProduct: true,
        rosivaCategory: "skincare",
        gender: "women",
        classificationReason: "matched 'serum'",
      },
    }),
    store,
    resolveCategory,
  });
  assert.equal(doc.isRosivaProduct, true);
  assert.equal(doc.rosivaCategory, "skincare");
  assert.equal(doc.gender, "women");
});
