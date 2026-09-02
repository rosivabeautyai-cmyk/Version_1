/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * ProductConnector — the generic interface every integration implements.
 *
 * A connector is created for ONE affiliate store. It receives:
 *   - `store`   the affiliateStores document (public config, no secrets)
 *   - `secrets` a plain object of private values resolved from the
 *               backend environment (never from Firestore, never sent
 *               to Flutter). May be empty.
 *
 * Adding a new company normally means:  Admin adds a store -> configures
 * a supported source -> Test Connection -> Save -> Sync.
 * Adding a brand-new KIND of source means: add one subclass here.
 * Nothing in the Flutter product UI changes either way.
 */

import { SyncError, ERROR_CODES } from "../lib/errors.mjs";

export class ProductConnector {
  /**
   * @param {object} store    affiliateStores document (must include `id`)
   * @param {object} [secrets] private values from the backend environment
   */
  constructor(store, secrets = {}) {
    if (!store || !store.id) {
      throw new SyncError(ERROR_CODES.INVALID_CONFIG, "connector requires a store with an id");
    }
    this.store = store;
    this.secrets = secrets || {};
  }

  /** Stable identifier for logs. */
  get name() {
    return `${this.constructor.name}(${this.store.slug || this.store.id})`;
  }

  /**
   * Validate config + reach the source + fetch a tiny sample.
   * MUST NOT throw for an expected failure — return the shape below.
   *
   * @return {Promise<{
   *   ok: boolean,
   *   productsDetected: number|null,   // total available, if the source reports it
   *   sample: object[],                // up to 5 RAW products
   *   error?: { code: string, userMessage: string, technical: string }
   * }>}
   */
  async testConnection() {
    throw new SyncError(ERROR_CODES.NOT_SUPPORTED, "testConnection not implemented");
  }

  /**
   * Async iterator over pages of RAW products. Each yielded value is an
   * array. Implementations MUST paginate / stream — never buffer a
   * whole catalog in memory.
   *
   * @param {object} [opts]
   * @param {number} [opts.pageSize]
   * @yields {object[]}  a page of raw products
   */
  // eslint-disable-next-line require-yield
  async *fetchProductPages() {
    throw new SyncError(ERROR_CODES.NOT_SUPPORTED, "fetchProductPages not implemented");
  }

  /**
   * Convenience: flatten fetchProductPages() into one async iterator of
   * individual raw products. Prefer the paged form in the sync engine.
   */
  async *fetchProducts(opts) {
    for await (const page of this.fetchProductPages(opts)) {
      for (const item of page) yield item;
    }
  }

  /**
   * Best-effort count of how many products this source will return,
   * used by the sync engine's daily write-budget guard BEFORE any
   * Firestore write. Return `null` if the count can't be known cheaply
   * (the engine then relies on its mid-run hard stop instead).
   *
   * The default implementation streams the pages and counts — safe
   * (zero Firestore writes) but re-downloads the feed. Connectors with
   * a cheaper way (a total in an API response, a fixed dataset)
   * override this.
   *
   * @param {object} [opts]
   * @param {number} [opts.timeoutMs]
   * @return {Promise<number|null>}
   */
  async estimateProductCount({ timeoutMs = 120000 } = {}) {
    const deadline = Date.now() + timeoutMs;
    let n = 0;
    try {
      for await (const page of this.fetchProductPages()) {
        n += page.length;
        if (Date.now() > deadline) return null; // too slow to be sure
      }
      return n;
    } catch {
      return null;
    }
  }

  /**
   * Map ONE source record to a loose "raw product" object the
   * Normalizer understands. Keep this dumb: field plumbing only, no
   * category/commission decisions (the Normalizer owns those).
   *
   * @param {object} record
   * @return {object} raw product
   */
  normalizeProduct(record) {
    return record;
  }

  /**
   * Return the click-out URL for a product. Prefer an official deep
   * link the source/network already provides. NEVER fabricate tracking
   * parameters.
   *
   * @param {object} record
   * @return {string|null}
   */
  buildAffiliateUrl(record) {
    return (
      record.affiliateUrl ||
      record.deepLink ||
      record.aw_deep_link ||
      record.productUrl ||
      record.url ||
      null
    );
  }
}
