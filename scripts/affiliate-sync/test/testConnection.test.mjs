import test from "node:test";
import assert from "node:assert/strict";

import { testAffiliateStoreConnection } from "../testConnection.mjs";
import { detectColumns } from "../lib/detectColumns.mjs";

const store = {
  id: "s1",
  slug: "s1",
  currency: "USD",
  integrationType: "product_feed",
};

/**
 * A connector whose testConnection() returns RAW rows (the documented
 * contract) plus detectedColumns, and whose normalizeProduct() maps a
 * fixed field layout. Proves the orchestrator normalizes the sample
 * exactly once and passes detectedColumns straight through.
 */
function fakeConnector(rows) {
  return {
    async testConnection() {
      return {
        ok: true,
        productsDetected: rows.length,
        sample: rows.slice(0, 5),
        detectedColumns: detectColumns(rows),
      };
    },
    normalizeProduct(rec) {
      return {
        externalProductId: rec.sku,
        name: rec.title,
        productUrl: rec.link,
        categoryName: rec.cat,
        price: rec.price,
      };
    },
  };
}

test("orchestrator: normalizes the raw sample once and yields a valid preview", async () => {
  const res = await testAffiliateStoreConnection({
    db: {},
    storeId: "s1",
    storeOverride: store,
    connector: fakeConnector([
      { sku: "A1", title: "Vitamin C Serum", link: "https://s/A1", cat: "Serum", price: "19.99" },
      { sku: "A2", title: "Rose Perfume", link: "https://s/A2", cat: "Perfume", price: "40" },
    ]),
  });

  assert.equal(res.ok, true);
  assert.equal(res.sampleCount, 2);
  assert.equal(res.sample[0].externalProductId, "A1");
  assert.equal(res.sample[0].name, "Vitamin C Serum");
  assert.equal(res.validation.invalid.length, 0);
});

test("orchestrator: passes detectedColumns through to the caller", async () => {
  const res = await testAffiliateStoreConnection({
    db: {},
    storeId: "s1",
    storeOverride: store,
    connector: fakeConnector([
      { sku: "A1", title: "X", link: "https://s/A1", cat: "Serum", price: "1" },
    ]),
  });
  assert.deepEqual(res.detectedColumns, ["sku", "title", "link", "cat", "price"]);
});

test("orchestrator: an unmapped feed (raw rows lack id/name) fails honestly", async () => {
  const res = await testAffiliateStoreConnection({
    db: {},
    storeId: "s1",
    storeOverride: store,
    connector: {
      async testConnection() {
        return {
          ok: true,
          productsDetected: 2,
          // feed uses columns the fake normalizer doesn't read
          sample: [{ ITEM: "A1", NAME: "X", URL: "https://s/A1" }],
          detectedColumns: ["ITEM", "NAME", "URL"],
        };
      },
      normalizeProduct(rec) {
        return { externalProductId: rec.sku, name: rec.title, productUrl: rec.link };
      },
    },
  });

  assert.equal(res.ok, false, "no sample row produced a valid product");
  assert.ok(res.validation.invalid.length > 0);
  // columns are still reported so the admin can fix the mapping
  assert.deepEqual(res.detectedColumns, ["ITEM", "NAME", "URL"]);
});
