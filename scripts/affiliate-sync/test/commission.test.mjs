import test from "node:test";
import assert from "node:assert/strict";

import { resolveCommission } from "../lib/commission.mjs";

test("priority 1: product-specific commission wins", () => {
  const r = resolveCommission({
    productCommissionRate: 12,
    store: { defaultCommissionRate: 8, commissionType: "percentage" },
  });
  assert.equal(r.rate, 12);
  assert.equal(r.source, "product");
});

test("priority 2: store default when no product rate", () => {
  const r = resolveCommission({
    productCommissionRate: null,
    store: { defaultCommissionRate: 8, commissionType: "percentage" },
  });
  assert.equal(r.rate, 8);
  assert.equal(r.source, "store");
});

test("priority 3: system default when neither is set", () => {
  const r = resolveCommission({ productCommissionRate: null, store: {} });
  assert.equal(r.rate, 0);
  assert.equal(r.source, "system");
});

test("invalid / negative rates are ignored, not used", () => {
  const r = resolveCommission({
    productCommissionRate: "not-a-number",
    store: { defaultCommissionRate: -5 },
  });
  assert.equal(r.source, "system");
  assert.equal(r.rate, 0);
});

test("commission type is carried from the store", () => {
  const r = resolveCommission({
    productCommissionRate: 5,
    store: { commissionType: "fixed" },
  });
  assert.equal(r.type, "fixed");
});
