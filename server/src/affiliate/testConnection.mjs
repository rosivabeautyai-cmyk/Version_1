/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * testAffiliateStoreConnection(storeId) — the backend side of the
 * Admin "Test Connection" button.
 *
 *   1. validate configuration
 *   2. connect to the feed / API / network
 *   3. fetch a small sample
 *   4. validate required fields on the sample
 *   5. return a SAFE result (never secrets)
 */

import { COLLECTIONS, INTEGRATION_TYPES } from "./lib/constants.mjs";
import { toSafeError, ERROR_CODES } from "./lib/errors.mjs";
import { buildCategoryResolver } from "./lib/categoryMapping.mjs";
import { normalizeProduct } from "./lib/normalizer.mjs";
import { resolveStoreSecrets } from "./lib/secrets.mjs";
import { getConnector } from "./connectors/index.mjs";

/**
 * @param {object} args
 * @param {object} args.db
 * @param {string} args.storeId
 * @param {object} [args.storeOverride]  test the given config WITHOUT saving it
 * @param {object} [args.env]
 * @param {object} [args.connector]  inject (tests)
 * @return {Promise<{
 *   ok: boolean,
 *   integrationType: string,
 *   productsDetected: number|null,
 *   sampleCount: number,
 *   sample: object[],          // normalized preview (safe: name/price/url/category)
 *   detectedColumns: string[], // raw source column/field names (for the mapping UI)
 *   validation: { validated: number, invalid: {code:string,detail:string}[] },
 *   error?: { code:string, userMessage:string, technical:string }
 * }>}
 */
export async function testAffiliateStoreConnection({ db, storeId, storeOverride, env = process.env, connector: injected } = {}) {
  let store;
  if (storeOverride && storeOverride.id) {
    store = storeOverride;
  } else {
    const snap = await db.collection(COLLECTIONS.STORES).doc(storeId).get();
    if (!snap.exists) {
      return {
        ok: false,
        integrationType: null,
        productsDetected: null,
        sampleCount: 0,
        sample: [],
        detectedColumns: [],
        validation: { validated: 0, invalid: [] },
        error: { code: ERROR_CODES.INVALID_CONFIG, userMessage: "Store not found.", technical: `affiliateStores/${storeId} missing` },
      };
    }
    store = { id: storeId, ...snap.data() };
  }

  const base = {
    ok: false,
    integrationType: store.integrationType || null,
    productsDetected: null,
    sampleCount: 0,
    sample: [],
    detectedColumns: [],
    validation: { validated: 0, invalid: [] },
  };

  if (store.integrationType === INTEGRATION_TYPES.MANUAL) {
    return {
      ...base,
      error: {
        code: ERROR_CODES.DATA_SOURCE_REQUIRED,
        userMessage:
          "This store is set to Manual — there is no automatic data source to test. " +
          "Switch to Product Feed, REST API, or Affiliate Network to enable automatic import.",
        technical: "manual integration",
      },
    };
  }

  let connector;
  try {
    const secrets = resolveStoreSecrets(store, env);
    connector = injected || getConnector(store, secrets);
  } catch (err) {
    return { ...base, error: toSafeError(err) };
  }

  let res;
  try {
    res = await connector.testConnection();
  } catch (err) {
    return { ...base, error: toSafeError(err) };
  }

  const rawSample = Array.isArray(res.sample) ? res.sample : [];
  const resolveCategory = buildCategoryResolver([]);
  const invalid = [];
  const preview = [];
  for (const rec of rawSample) {
    const raw = typeof connector.normalizeProduct === "function" ? tryNormalize(connector, rec) : rec;
    const norm = normalizeProduct({ raw, store, resolveCategory });
    if (!norm.ok) {
      invalid.push({ code: norm.code, detail: norm.technical });
      continue;
    }
    preview.push({
      externalProductId: norm.doc.externalProductId,
      name: norm.doc.name,
      brand: norm.doc.brand,
      price: norm.doc.price,
      currency: norm.doc.currency,
      category: norm.doc.rosivaCategory,
      imageUrl: norm.doc.imageUrl,
      hasAffiliateUrl: Boolean(norm.doc.affiliateUrl),
    });
  }

  return {
    ...base,
    ok: Boolean(res.ok) && preview.length > 0,
    productsDetected: res.productsDetected ?? null,
    sampleCount: preview.length,
    sample: preview,
    detectedColumns: Array.isArray(res.detectedColumns)
      ? res.detectedColumns.slice(0, 100)
      : [],
    validation: { validated: rawSample.length, invalid },
    error: res.error || (preview.length === 0
      ? { code: ERROR_CODES.MALFORMED_PRODUCT, userMessage: "Connected, but no valid products were found in the sample.", technical: "0 valid sample products" }
      : undefined),
  };
}

function tryNormalize(connector, rec) {
  try {
    return connector.normalizeProduct(rec);
  } catch {
    return rec;
  }
}
