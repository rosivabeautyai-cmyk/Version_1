/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Shared vocabulary for the affiliate sync system. These string values
 * are the contract between:
 *   - the Flutter Admin UI (affiliate_store_model.dart mirrors them)
 *   - the `affiliateStores` Firestore documents
 *   - the connector framework here
 *
 * Keep them in sync with lib/Feature/admin/data/models/affiliate_store_model.dart.
 */

export const INTEGRATION_TYPES = Object.freeze({
  PRODUCT_FEED: "product_feed",
  REST_API: "rest_api",
  AFFILIATE_NETWORK: "affiliate_network",
  MANUAL: "manual",
});

export const FEED_FORMATS = Object.freeze({
  CSV: "csv",
  XML: "xml",
  JSON: "json",
});

export const COMMISSION_TYPES = Object.freeze({
  PERCENTAGE: "percentage",
  FIXED: "fixed",
});

export const STORE_STATUS = Object.freeze({
  ACTIVE: "active",
  INACTIVE: "inactive",
});

export const SYNC_STATUS = Object.freeze({
  IDLE: "idle",
  QUEUED: "queued",
  RUNNING: "running",
  SUCCESS: "success",
  ERROR: "error",
  // A run that completed but was intentionally NOT allowed to
  // deactivate products because the source returned far fewer than
  // expected (see MAX_CATALOG_DROP_RATIO). Needs a human to confirm
  // before the next sync is trusted to prune.
  NEEDS_REVIEW: "needs_review",
});

export const SYNC_FREQUENCIES = Object.freeze({
  "6_hours": 6 * 60 * 60 * 1000,
  "12_hours": 12 * 60 * 60 * 1000,
  daily: 24 * 60 * 60 * 1000,
  weekly: 7 * 24 * 60 * 60 * 1000,
});

export const TRIGGERED_BY = Object.freeze({
  ADMIN: "admin",
  SCHEDULED: "scheduled",
  SYSTEM: "system",
});

export const AVAILABILITY = Object.freeze({
  IN_STOCK: "in_stock",
  OUT_OF_STOCK: "out_of_stock",
  UNKNOWN: "unknown",
});

/** Firestore collection names — single source of truth. */
export const COLLECTIONS = Object.freeze({
  STORES: "affiliateStores",
  SYNC_LOGS: "affiliateSyncLogs",
  SYNC_JOBS: "affiliateSyncJobs",
  CATEGORY_MAPPINGS: "categoryMappings",
  PRODUCTS: "products",
  CATEGORIES: "categories",
});

/** Product source tags (products.source). */
export const PRODUCT_SOURCE = Object.freeze({
  AWIN: "awin", // legacy scripts/awin-sync documents
  AFFILIATE: "affiliate", // written by this generalized engine
  ADMIN: "admin", // hand-authored in the Admin panel
});

/**
 * Default system commission (percent) used only when neither the
 * product nor the store carries a configured rate. This is CONFIGURED
 * metadata, never a claim of confirmed earnings.
 */
export const DEFAULT_SYSTEM_COMMISSION_RATE = 0;

/** How many products a single sync run will process before stopping. */
export const MAX_PRODUCTS_PER_RUN = 200000;

/**
 * Catalog-safety guard for the deactivation sweep.
 *
 * If a sync run sees FAR fewer products than the store currently has
 * active, that is far more likely to be a broken/expired/empty feed
 * than a real catalog change — so the sweep is SKIPPED and the run is
 * flagged instead of silently deactivating everything.
 *
 *  - zero products seen        -> run marked FAILED, sweep skipped
 *  - active-count drop > this  -> run marked NEEDS_REVIEW, sweep skipped
 *
 * 0.8 = "more than an 80% drop in active products". A brand-new store
 * (0 active) is never affected.
 */
export const MAX_CATALOG_DROP_RATIO = 0.8;

/** Firestore hard limit per batched write. */
export const WRITE_BATCH_SIZE = 400;
