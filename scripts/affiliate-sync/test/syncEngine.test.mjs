import test from "node:test";
import assert from "node:assert/strict";

import { FakeFirestore } from "./fakeFirestore.mjs";
import { syncAffiliateStore } from "../syncEngine.mjs";
import { testAffiliateStoreConnection } from "../testConnection.mjs";
import { MockConnector } from "../connectors/MockConnector.mjs";
import { COLLECTIONS } from "../lib/constants.mjs";

const STORE_ID = "store_mock";

function seedDb() {
  return new FakeFirestore({
    [COLLECTIONS.STORES]: {
      [STORE_ID]: {
        name: "Mock Beauty",
        slug: "mock-beauty",
        currency: "USD",
        integrationType: "mock",
        affiliateNetwork: "mock",
        defaultCommissionRate: 8,
        commissionType: "percentage",
        status: "active",
        syncEnabled: true,
        syncFrequency: "daily",
      },
    },
  });
}

test("Test Connection returns a safe sample, never secrets", async () => {
  const db = seedDb();
  const res = await testAffiliateStoreConnection({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });
  assert.equal(res.ok, true);
  assert.equal(res.productsDetected, 8);
  assert.ok(res.sample.length > 0 && res.sample.length <= 5);
  for (const p of res.sample) {
    assert.ok(p.name);
    assert.equal("secrets" in p, false);
    assert.equal("apiKey" in p, false);
  }
});

test("first sync inserts, second identical sync updates (no duplicates)", async () => {
  const db = seedDb();
  const clock = () => "2026-02-01T00:00:00.000Z";

  const run1 = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "stable" }),
    clock,
  });
  assert.equal(run1.status, "success");
  assert.equal(run1.newProducts, 8);
  assert.equal(run1.updatedProducts, 0);
  assert.equal(run1.deactivatedProducts, 0);

  const productsAfter1 = Object.keys(db.dump(COLLECTIONS.PRODUCTS));
  assert.equal(productsAfter1.length, 8);
  assert.ok(productsAfter1.every((id) => id.startsWith(`${STORE_ID}:`)));

  const run2 = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "stable" }),
    clock,
  });
  assert.equal(run2.newProducts, 0);
  assert.equal(run2.updatedProducts, 8);
  assert.equal(Object.keys(db.dump(COLLECTIONS.PRODUCTS)).length, 8, "still 8 — upsert, not duplicate");
});

test("products missing from a later feed are deactivated, not deleted", async () => {
  const db = seedDb();

  await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "stable" }),
  });

  const drift = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "drift" }),
  });
  assert.equal(drift.deactivatedProducts, 2);

  const products = db.dump(COLLECTIONS.PRODUCTS);
  assert.equal(Object.keys(products).length, 8, "no hard delete");
  const inactive = Object.values(products).filter((p) => p.isActive === false);
  assert.equal(inactive.length, 2);
  for (const p of inactive) assert.equal(p.availability, "out_of_stock");
});

test("store bookkeeping + a sync log are written", async () => {
  const db = seedDb();
  const log = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    triggeredBy: "admin",
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });

  const store = db.dump(COLLECTIONS.STORES)[STORE_ID];
  assert.equal(store.syncStatus, "success");
  assert.equal(store.productCount, 8);
  assert.ok(store.lastSyncAt);
  assert.ok(store.nextSyncAt);

  const logs = Object.values(db.dump(COLLECTIONS.SYNC_LOGS));
  assert.equal(logs.length, 1);
  assert.equal(logs[0].triggeredBy, "admin");
  assert.equal(logs[0].newProducts, 8);
  assert.equal(logs[0].id, log.id);
});

test("commission priority: product rate on the doc beats the store default", async () => {
  const db = seedDb();

  class CommissionConnector extends MockConnector {
    normalizeProduct(record) {
      const raw = super.normalizeProduct(record);
      if (record.externalProductId === "SERUM-001") raw.commissionRate = 15;
      return raw;
    }
  }

  await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new CommissionConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });

  const products = db.dump(COLLECTIONS.PRODUCTS);
  const serum = products[`${STORE_ID}:SERUM-001`];
  const other = products[`${STORE_ID}:CREAM-002`];
  assert.equal(serum.commissionRate, 15);
  assert.equal(serum.commissionSource, "product");
  assert.equal(other.commissionRate, 8);
  assert.equal(other.commissionSource, "store");
});

test("inactive store is refused unless forced", async () => {
  const db = seedDb();
  await db.collection(COLLECTIONS.STORES).doc(STORE_ID).set({ status: "inactive" }, { merge: true });

  const log = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });
  assert.equal(log.status, "error");
  assert.equal(log.errorCode, "invalid_config");
  assert.equal(Object.keys(db.dump(COLLECTIONS.PRODUCTS)).length, 0);
});

test("catalog-safety guard: an EMPTY feed skips the sweep and marks the run FAILED", async () => {
  const db = seedDb();
  await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });
  assert.equal(Object.keys(db.dump(COLLECTIONS.PRODUCTS)).length, 8);

  const emptyConnector = {
    name: "EmptyConnector",
    normalizeProduct: (r) => r,
    async *fetchProductPages() {},
  };
  const log = await syncAffiliateStore({ db, storeId: STORE_ID, connector: emptyConnector });

  assert.equal(log.status, "error");
  assert.equal(log.errorCode, "empty_feed");
  assert.equal(log.sweepSkipped, "empty_feed");
  assert.equal(log.deactivatedProducts, 0);

  const products = db.dump(COLLECTIONS.PRODUCTS);
  assert.equal(Object.keys(products).length, 8, "nothing deleted");
  assert.equal(
    Object.values(products).every((p) => p.isActive !== false),
    true,
    "nothing deactivated — catalog left untouched",
  );
  const store = db.dump(COLLECTIONS.STORES)[STORE_ID];
  assert.equal(store.syncStatus, "error");
  assert.equal(store.productCount, 8, "productCount not overwritten on an empty-feed run");
});

test("catalog-safety guard: a >80% drop skips the sweep and marks the run NEEDS_REVIEW", async () => {
  const db = seedDb();
  await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });

  class TinyConnector extends MockConnector {
    _dataset() {
      return super._dataset().slice(0, 1); // 1 of 8 -> 87.5% drop
    }
  }
  const log = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new TinyConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });

  assert.equal(log.status, "needs_review");
  assert.equal(log.errorCode, "catalog_drop");
  assert.equal(log.sweepSkipped, "catalog_drop");
  assert.equal(log.deactivatedProducts, 0);
  assert.equal(log.seenCount, 1);
  assert.equal(log.existingActiveCount, 8);

  const products = db.dump(COLLECTIONS.PRODUCTS);
  assert.equal(
    Object.values(products).filter((p) => p.isActive === false).length,
    0,
    "no products deactivated on a large-drop run",
  );
  const store = db.dump(COLLECTIONS.STORES)[STORE_ID];
  assert.equal(store.syncStatus, "needs_review");
  assert.equal(store.pendingReview, true);
});

test("catalog-safety guard: a moderate drop (<=80%) still deactivates normally", async () => {
  const db = seedDb();
  await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "stable" }),
  });
  const log = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new MockConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }, {}, { variant: "drift" }),
  });
  assert.equal(log.sweepSkipped, null);
  assert.equal(log.status, "success");
  assert.equal(log.deactivatedProducts, 2);
});

test("malformed products are counted as failed, the rest still sync", async () => {
  const db = seedDb();

  class FlakyConnector extends MockConnector {
    normalizeProduct(record) {
      const raw = super.normalizeProduct(record);
      if (record.externalProductId === "LIP-004") raw.name = ""; // invalid
      return raw;
    }
  }

  const log = await syncAffiliateStore({
    db,
    storeId: STORE_ID,
    connector: new FlakyConnector({ id: STORE_ID, slug: "mock-beauty", currency: "USD" }),
  });
  assert.equal(log.failedProducts, 1);
  assert.equal(log.newProducts, 7);
  assert.equal(log.status, "partial");
  assert.equal(log.failureSamples[0].code, "missing_product_name");
});
