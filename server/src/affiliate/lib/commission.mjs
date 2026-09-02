/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Commission resolution.
 *
 * Priority (highest first):
 *   1. product-specific commission  (from the feed/API, when the source
 *      actually provides per-product commission info)
 *   2. store / program default commission  (affiliateStores.defaultCommissionRate)
 *   3. system default commission            (constants.DEFAULT_SYSTEM_COMMISSION_RATE)
 *
 * This function returns CONFIGURED commission metadata only. It never
 * represents confirmed affiliate earnings — those come from the
 * affiliate network's reporting API and are stored separately.
 */

import { DEFAULT_SYSTEM_COMMISSION_RATE, COMMISSION_TYPES } from "./constants.mjs";

function toRate(value) {
  if (value == null) return null;
  const n = typeof value === "number" ? value : parseFloat(String(value));
  if (!Number.isFinite(n) || n < 0) return null;
  return n;
}

/**
 * @param {object} args
 * @param {number|string|null} [args.productCommissionRate] rate the source gave for THIS product
 * @param {object} args.store  the affiliateStores document
 * @return {{ rate: number, type: string, source: 'product'|'store'|'system' }}
 */
export function resolveCommission({ productCommissionRate, store } = {}) {
  const productRate = toRate(productCommissionRate);
  if (productRate != null) {
    return {
      rate: productRate,
      type: store?.commissionType || COMMISSION_TYPES.PERCENTAGE,
      source: "product",
    };
  }

  const storeRate = toRate(store?.defaultCommissionRate);
  if (storeRate != null) {
    return {
      rate: storeRate,
      type: store?.commissionType || COMMISSION_TYPES.PERCENTAGE,
      source: "store",
    };
  }

  return {
    rate: DEFAULT_SYSTEM_COMMISSION_RATE,
    type: COMMISSION_TYPES.PERCENTAGE,
    source: "system",
  };
}
