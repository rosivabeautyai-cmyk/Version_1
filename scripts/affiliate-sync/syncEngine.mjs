/**
 * syncAffiliateStore(storeId) — the generalized product sync.
 *
 * Flow (matches the brief, section 13):
 *   1. load store config
 *   2. verify store is active + sync enabled
 *   3. resolve private credentials from the backend environment
 *   4. select the connector
 *   5. (optional) test the connection first
 *   6. fetch products in pages/batches (never buffer the whole catalog)
 *   7. normalize each product
 *   8. validate required fields
 *   9. UPSERT products into Firestore (batched)
 *  10. mark products no longer in the source as isActive:false (never hard-delete)
 *  11. update productCount
 *  12. update lastSyncAt / nextSyncAt
 *  13. update syncStatus
 *  14. create an affiliateSyncLogs record
 *  15. log errors WITHOUT exposing secrets
 *
 * Reliability: per-page retry with exponential backoff, an overall
 * timeout budget, and idempotent doc ids (storeId + externalProductId)
 * so re-running updates instead of duplicating.
 *
 * This module is Firestore-shaped but not Firestore-specific: pass any
 * object implementing the small `db` surface used below (collection/doc/
 * get/set/update/where/batch). Tests inject an in-memory fake.
 */

import {
  COLLECTIONS,
  SYNC_STATUS,
  STORE_STATUS,
  SYNC_FREQUENCIES,
  TRIGGERED_BY,
  WRITE_BATCH_SIZE,
  MAX_PRODUCTS_PER_RUN,
  MAX_CATALOG_DROP_RATIO,
  BUDGET_BOOKKEEPING_RESERVE,
} from "./lib/constants.mjs";
import { SyncError, ERROR_CODES, toSafeError, redact } from "./lib/errors.mjs";
import { buildCategoryResolver } from "./lib/categoryMapping.mjs";
import { normalizeProduct } from "./lib/normalizer.mjs";
import { resolveStoreSecrets } from "./lib/secrets.mjs";
import { getConnector } from "./connectors/index.mjs";
import {
  utcDayKey,
  dailyWriteBudget,
  writesUsedToday,
  addWritesToday,
} from "./lib/writeBudget.mjs";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function withRetry(fn, { retries = 3, baseDelayMs = 500, label = "op", logger } = {}) {
  let attempt = 0;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    try {
      return await fn();
    } catch (err) {
      attempt += 1;
      const code = err instanceof SyncError ? err.code : null;
      const fatal =
        code === ERROR_CODES.INVALID_CONFIG ||
        code === ERROR_CODES.INVALID_CREDENTIALS ||
        code === ERROR_CODES.NOT_SUPPORTED ||
        code === ERROR_CODES.DATA_SOURCE_REQUIRED;
      if (fatal || attempt > retries) throw err;
      const delay = baseDelayMs * 2 ** (attempt - 1) + Math.floor(Math.random() * 200);
      logger?.warn?.(`${label} failed (attempt ${attempt}/${retries}), retrying in ${delay}ms: ${redact(String(err?.message || err))}`);
      await sleep(delay);
    }
  }
}

function nextSyncIso(frequency, fromIso) {
  const ms = SYNC_FREQUENCIES[frequency];
  if (!ms) return null;
  return new Date(new Date(fromIso).getTime() + ms).toISOString();
}

/**
 * @param {object} args
 * @param {object} args.db
 * @param {string} args.storeId
 * @param {string} [args.triggeredBy]  admin | scheduled | system
 * @param {object} [args.env]          process.env-shaped, for secret resolution
 * @param {object} [args.connector]    inject a connector (tests / mock)
 * @param {() => string} [args.clock]  returns an ISO string
 * @param {object} [args.logger]       { info, warn, error }
 * @param {number} [args.overallTimeoutMs]
 * @param {boolean} [args.force]       run even if store inactive / sync disabled
 * @param {object} [args.fieldValue]   firebase-admin FieldValue (for the write-budget counter's `.increment`)
 * @return {Promise<object>}  the sync log record that was written
 */
export async function syncAffiliateStore({
  db,
  storeId,
  triggeredBy = TRIGGERED_BY.SYSTEM,
  env = process.env,
  connector: injectedConnector,
  clock = () => new Date().toISOString(),
  logger = console,
  overallTimeoutMs = 25 * 60 * 1000,
  force = false,
  fieldValue = null,
} = {}) {
  if (!db) throw new SyncError(ERROR_CODES.INVALID_CONFIG, "db is required");
  if (!storeId) throw new SyncError(ERROR_CODES.INVALID_CONFIG, "storeId is required");

  const startedAt = clock();
  const deadline = Date.now() + overallTimeoutMs;
  const storeRef = db.collection(COLLECTIONS.STORES).doc(storeId);

  // 1. load store config
  const storeSnap = await storeRef.get();
  if (!storeSnap.exists) {
    throw new SyncError(ERROR_CODES.INVALID_CONFIG, `affiliateStores/${storeId} not found`);
  }
  const store = { id: storeId, ...storeSnap.data() };

  const result = {
    storeId,
    startedAt,
    completedAt: null,
    status: "success",
    triggeredBy,
    totalFetched: 0,
    newProducts: 0,
    updatedProducts: 0,
    deactivatedProducts: 0,
    failedProducts: 0,
    errorSummary: "",
    errorCode: null,
    failureSamples: [],
    // Non-Awin eligibility: products written but hidden from shoppers,
    // with a reason (men's filter / unresolved category).
    excludedProducts: 0,
    excludedSamples: [],
    // Catalog-safety guard bookkeeping (see MAX_CATALOG_DROP_RATIO).
    sweepSkipped: null, // null | "empty_feed" | "catalog_drop"
    seenCount: 0,
    existingActiveCount: 0,
    // Firestore write-budget guard (see DEFAULT_DAILY_WRITE_BUDGET).
    writesCommitted: 0,
    budgetStopped: false,
    estimatedWrites: null,
  };

  try {
    // 2. verify active + enabled (recorded as an error log, not a throw,
    //    so a disabled store still leaves an audit trail)
    if (!force) {
      if (store.status && store.status !== STORE_STATUS.ACTIVE) {
        throw new SyncError(ERROR_CODES.INVALID_CONFIG, `store ${storeId} is not active`);
      }
      if (store.syncEnabled === false) {
        throw new SyncError(ERROR_CODES.INVALID_CONFIG, `store ${storeId} has sync disabled`);
      }
    }

    // 13 (part) — mark running
    await storeRef.set(
      { syncStatus: SYNC_STATUS.RUNNING, lastSyncStartedAt: startedAt, updatedAt: startedAt },
      { merge: true },
    );

    // 3. secrets from the backend environment (never Firestore)
    const secrets = resolveStoreSecrets(store, env);

    // 4. select connector
    const connector = injectedConnector || getConnector(store, secrets);
    logger.info?.(`[affiliate-sync] ${storeId}: using ${connector.name}`);

    // category resolver (admin-configurable mappings + keyword fallback)
    let mappingDocs = [];
    try {
      const mapSnap = await db.collection(COLLECTIONS.CATEGORY_MAPPINGS).get();
      mappingDocs = mapSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    } catch {
      // no mappings collection yet — keyword normalizer still applies
    }
    const resolveCategory = buildCategoryResolver(mappingDocs);

    // 10 (prep) — snapshot the ids we currently have for this store so
    // we can deactivate the ones the source no longer returns. Also
    // count how many are currently ACTIVE — the catalog-safety guard
    // below compares the incoming feed against that.
    const existingIds = new Set();
    let existingActiveCount = 0;
    try {
      const existingSnap = await db
        .collection(COLLECTIONS.PRODUCTS)
        .where("storeId", "==", storeId)
        .get();
      for (const d of existingSnap.docs) {
        existingIds.add(d.id);
        if (d.data()?.isActive !== false) existingActiveCount += 1;
      }
    } catch (err) {
      logger.warn?.(`[affiliate-sync] ${storeId}: could not list existing products: ${redact(String(err?.message || err))}`);
    }
    result.existingActiveCount = existingActiveCount;

    // ---- Firestore write-budget pre-flight (Spark plan safety) --------
    // Estimate this run's writes and refuse to start if it would push
    // the day's total past the budget. A feed I don't control must never
    // be able to burn the 20k/day quota and break Awin + the app.
    const dayKey = utcDayKey(new Date(clock()));
    const budget = dailyWriteBudget(env);
    const usedToday = await writesUsedToday(db, dayKey);
    const remaining = budget - usedToday;

    let estimate = null;
    try {
      estimate = await connector.estimateProductCount?.();
    } catch {
      estimate = null;
    }
    result.estimatedWrites = estimate == null ? null : estimate + existingIds.size;

    if (estimate != null) {
      // worst case: every incoming product is a write, AND every
      // existing product not returned this run is a deactivation write.
      const worstCase = estimate + existingIds.size + BUDGET_BOOKKEEPING_RESERVE;
      if (worstCase > remaining) {
        const msg =
          `Estimated ~${worstCase} Firestore writes would exceed today's remaining ` +
          `budget (${remaining} of ${budget} left). Sync NOT started — catalog untouched. ` +
          `Re-run after 00:00 UTC, raise AFFILIATE_DAILY_WRITE_BUDGET, or split the feed.`;
        logger.warn?.(`[affiliate-sync] ${storeId}: WRITE-BUDGET pre-flight blocked. ${msg}`);
        result.status = "needs_review";
        result.errorCode = ERROR_CODES.WRITE_BUDGET;
        result.errorSummary = msg;
        result.budgetStopped = true;
        result.completedAt = clock();
        await storeRef.set(
          {
            syncStatus: SYNC_STATUS.NEEDS_REVIEW,
            lastSyncStatus: "needs_review",
            lastSyncAt: result.completedAt,
            lastSyncError: msg,
            pendingReview: true,
            nextSyncAt: nextSyncIso(store.syncFrequency, result.completedAt),
            updatedAt: result.completedAt,
          },
          { merge: true },
        );
        const preLogRef = db.collection(COLLECTIONS.SYNC_LOGS).doc();
        const preLog = { id: preLogRef.id, ...result };
        await preLogRef.set(preLog);
        await addWritesToday(db, BUDGET_BOOKKEEPING_RESERVE, fieldValue, dayKey);
        return preLog;
      }
    }
    // If estimate is null (unknown feed size) we still proceed, but the
    // per-batch hard stop below caps the damage.
    const budgetCeiling = usedToday + remaining; // == budget; kept explicit
    // -----------------------------------------------------------------

    const seenIds = new Set();

    // 6–9 — paginated fetch + normalize + validate + upsert
    let batch = db.batch();
    let batchCount = 0;
    let budgetHit = false;
    const nowIso = clock();

    const flush = async () => {
      if (batchCount === 0) return;
      const toCommit = batch;
      const n = batchCount;
      batch = db.batch();
      batchCount = 0;
      await withRetry(() => toCommit.commit(), { label: "batch.commit", logger });
      result.writesCommitted += n;
    };

    // Would writing ONE more product push today's total past the
    // budget? Checked BEFORE the row is added to the batch, so whatever
    // is already staged always fits and can be safely flushed. When it
    // trips we stop cleanly: products written so far are fine
    // (merge:true), the sweep is skipped, the run is flagged
    // needs_review.
    const oneMoreWouldExceed = () =>
      usedToday + result.writesCommitted + batchCount + 1 + BUDGET_BOOKKEEPING_RESERVE >
      budgetCeiling;

    let pageNo = 0;
    for await (const page of connector.fetchProductPages()) {
      if (budgetHit) break;
      if (Date.now() > deadline) {
        throw new SyncError(ERROR_CODES.TIMEOUT, "overall sync time budget exceeded");
      }
      pageNo += 1;
      const rawPage = await withRetry(
        async () => page.map((rec) => (typeof connector.normalizeProduct === "function" ? safeNormalize(connector, rec) : rec)),
        { label: `page ${pageNo} normalize`, logger, retries: 1 },
      );

      for (const raw of rawPage) {
        result.totalFetched += 1;
        if (result.totalFetched > MAX_PRODUCTS_PER_RUN) {
          throw new SyncError(ERROR_CODES.SERVICE_UNAVAILABLE, `exceeded MAX_PRODUCTS_PER_RUN (${MAX_PRODUCTS_PER_RUN})`);
        }

        const norm = normalizeProduct({ raw, store, resolveCategory, nowIso });
        if (!norm.ok) {
          result.failedProducts += 1;
          if (result.failureSamples.length < 10) {
            result.failureSamples.push({ code: norm.code, detail: redact(norm.technical) });
          }
          continue;
        }

        if (seenIds.has(norm.docId)) {
          // duplicate within the same feed — ignore the 2nd occurrence
          result.failedProducts += 1;
          if (result.failureSamples.length < 10) {
            result.failureSamples.push({ code: ERROR_CODES.DUPLICATE_PRODUCT, detail: norm.docId });
          }
          continue;
        }
        if (oneMoreWouldExceed()) {
          budgetHit = true;
          logger.warn?.(
            `[affiliate-sync] ${storeId}: WRITE-BUDGET hard stop after ${result.writesCommitted + batchCount} writes ` +
              `(day total ~${usedToday + result.writesCommitted + batchCount}/${budget}). Remaining products NOT written; sweep skipped.`,
          );
          break;
        }

        seenIds.add(norm.docId);

        // Written-but-hidden (men's filter / unresolved category). Still
        // upserted below so it's visible under the admin Ineligible
        // filter with `exclusionReason`.
        if (norm.doc.isRosivaProduct === false && norm.doc.exclusionReason) {
          result.excludedProducts += 1;
          if (result.excludedSamples.length < 10) {
            result.excludedSamples.push({
              code: norm.doc.exclusionReason,
              detail: `${norm.doc.name}`.slice(0, 120),
            });
          }
        }

        const isNew = !existingIds.has(norm.docId);
        if (isNew) result.newProducts += 1;
        else result.updatedProducts += 1;

        const ref = db.collection(COLLECTIONS.PRODUCTS).doc(norm.docId);
        // merge:true so admin-managed keys (adminOverrides, featured,
        // countryOffers, ...) are preserved across syncs.
        batch.set(ref, norm.doc, { merge: true });
        batchCount += 1;
        if (batchCount >= WRITE_BATCH_SIZE) await flush();
      }
      if (budgetHit) break;
    }
    // Whatever is staged fits the budget by construction — commit it.
    await flush();

    // 10 — deactivate the products the source stopped returning —
    // UNLESS a safety guard trips: the write-budget hard stop, an empty
    // feed, or a >80% catalog drop.
    const seenCount = seenIds.size;
    result.seenCount = seenCount;
    const dropRatio =
      existingActiveCount > 0 ? (existingActiveCount - seenCount) / existingActiveCount : 0;

    if (budgetHit) {
      result.sweepSkipped = "write_budget";
      // no logging here — already warned at the stop point
    } else if (seenCount === 0) {
      result.sweepSkipped = "empty_feed";
      logger.warn?.(
        `[affiliate-sync] ${storeId}: deactivation sweep SKIPPED — source returned 0 products ` +
          `(store has ${existingActiveCount} active). Run marked FAILED; catalog left untouched.`,
      );
    } else if (dropRatio > MAX_CATALOG_DROP_RATIO) {
      result.sweepSkipped = "catalog_drop";
      logger.warn?.(
        `[affiliate-sync] ${storeId}: deactivation sweep SKIPPED — source returned ${seenCount} ` +
          `of ${existingActiveCount} active products (${Math.round(dropRatio * 100)}% drop > ` +
          `${Math.round(MAX_CATALOG_DROP_RATIO * 100)}%). Run flagged for review; nothing deactivated.`,
      );
    } else {
      const goneIds = [...existingIds].filter((id) => !seenIds.has(id));
      for (let i = 0; i < goneIds.length; i += WRITE_BATCH_SIZE) {
        const slice = goneIds.slice(i, i + WRITE_BATCH_SIZE);
        // Same budget ceiling applies to deactivation writes.
        if (
          usedToday + result.writesCommitted + result.deactivatedProducts + slice.length + BUDGET_BOOKKEEPING_RESERVE >
          budgetCeiling
        ) {
          budgetHit = true;
          result.sweepSkipped = "write_budget";
          logger.warn?.(
            `[affiliate-sync] ${storeId}: WRITE-BUDGET stop during deactivation after ${result.deactivatedProducts} of ${goneIds.length}.`,
          );
          break;
        }
        const b = db.batch();
        for (const id of slice) {
          b.set(
            db.collection(COLLECTIONS.PRODUCTS).doc(id),
            { isActive: false, active: false, availability: "out_of_stock", inStock: false, lastSyncedAt: nowIso, updatedAt: nowIso },
            { merge: true },
          );
        }
        await withRetry(() => b.commit(), { label: "deactivate batch", logger });
        result.deactivatedProducts += slice.length;
      }
    }

    // 11–13 — store bookkeeping
    const completedAt = clock();
    result.completedAt = completedAt;
    const nextSyncAt = nextSyncIso(store.syncFrequency, completedAt);

    if (result.sweepSkipped === "write_budget") {
      result.status = "needs_review";
      result.errorCode = ERROR_CODES.WRITE_BUDGET;
      result.errorSummary =
        `Stopped after ~${result.writesCommitted} Firestore writes to stay within today's ` +
        `budget (~${usedToday + result.writesCommitted}/${budget}). ${result.newProducts + result.updatedProducts} ` +
        `product(s) written before stopping; the rest were not, and nothing was deactivated. ` +
        `Re-run after 00:00 UTC or raise AFFILIATE_DAILY_WRITE_BUDGET.`;
      await storeRef.set(
        {
          syncStatus: SYNC_STATUS.NEEDS_REVIEW,
          lastSyncStatus: "needs_review",
          lastSyncAt: completedAt,
          lastSyncError: result.errorSummary,
          pendingReview: true,
          nextSyncAt,
          // productCount NOT changed — the run is incomplete.
          lastSyncSummary: {
            newProducts: result.newProducts,
            updatedProducts: result.updatedProducts,
            deactivatedProducts: 0,
            failedProducts: result.failedProducts,
            excludedProducts: result.excludedProducts,
            totalFetched: result.totalFetched,
          },
          updatedAt: completedAt,
        },
        { merge: true },
      );
    } else if (result.sweepSkipped === "empty_feed") {
      result.status = "error";
      result.errorCode = ERROR_CODES.EMPTY_FEED;
      result.errorSummary =
        `Source returned 0 products (store has ${existingActiveCount} active). ` +
        `Deactivation skipped; catalog left untouched.`;
      await storeRef.set(
        {
          syncStatus: SYNC_STATUS.ERROR,
          lastSyncStatus: "error",
          lastSyncAt: completedAt,
          lastSyncError: result.errorSummary,
          nextSyncAt,
          // productCount deliberately NOT changed — nothing was pruned.
          updatedAt: completedAt,
        },
        { merge: true },
      );
    } else if (result.sweepSkipped === "catalog_drop") {
      result.status = "needs_review";
      result.errorCode = ERROR_CODES.CATALOG_DROP;
      result.errorSummary =
        `Source returned ${seenCount} of ${existingActiveCount} active products ` +
        `(${Math.round(dropRatio * 100)}% drop). Deactivation skipped — review the source, then re-run.`;
      await storeRef.set(
        {
          syncStatus: SYNC_STATUS.NEEDS_REVIEW,
          lastSyncStatus: "needs_review",
          lastSyncAt: completedAt,
          lastSyncError: result.errorSummary,
          pendingReview: true,
          nextSyncAt,
          // productCount deliberately NOT changed — missing products
          // are still active pending review.
          lastSyncSummary: {
            newProducts: result.newProducts,
            updatedProducts: result.updatedProducts,
            deactivatedProducts: 0,
            failedProducts: result.failedProducts,
            excludedProducts: result.excludedProducts,
            totalFetched: result.totalFetched,
          },
          updatedAt: completedAt,
        },
        { merge: true },
      );
    } else {
      await storeRef.set(
        {
          syncStatus: SYNC_STATUS.SUCCESS,
          lastSyncAt: completedAt,
          lastSyncStatus: "success",
          lastSyncError: null,
          pendingReview: false,
          nextSyncAt,
          productCount: seenCount, // products still present this run
          lastSyncSummary: {
            newProducts: result.newProducts,
            updatedProducts: result.updatedProducts,
            deactivatedProducts: result.deactivatedProducts,
            failedProducts: result.failedProducts,
            excludedProducts: result.excludedProducts,
            totalFetched: result.totalFetched,
          },
          updatedAt: completedAt,
        },
        { merge: true },
      );

      if (result.failedProducts > 0) {
        result.status = "partial";
        result.errorSummary = `${result.failedProducts} product(s) skipped; see failureSamples`;
      }
    }
  } catch (err) {
    const safe = toSafeError(err);
    result.status = "error";
    result.completedAt = clock();
    result.errorCode = safe.code;
    result.errorSummary = safe.userMessage;
    logger.error?.(`[affiliate-sync] ${storeId} FAILED [${safe.code}]: ${safe.technical}`);
    await storeRef.set(
      {
        syncStatus: SYNC_STATUS.ERROR,
        lastSyncStatus: "error",
        lastSyncAt: result.completedAt,
        lastSyncError: safe.userMessage,
        updatedAt: result.completedAt,
      },
      { merge: true },
    );
  }

  // 14 — sync history record
  const logRef = db.collection(COLLECTIONS.SYNC_LOGS).doc();
  const logDoc = { id: logRef.id, ...result };
  await logRef.set(logDoc);

  // 15 — charge today's Firestore-write budget with what this run
  // actually committed (+ a small bookkeeping reserve). Best-effort;
  // never fails the sync.
  try {
    const dk = utcDayKey(new Date((result.completedAt || result.startedAt)));
    await addWritesToday(
      db,
      (result.writesCommitted || 0) + (result.deactivatedProducts || 0) + BUDGET_BOOKKEEPING_RESERVE,
      fieldValue,
      dk,
    );
  } catch {
    /* accounting is best-effort */
  }

  return logDoc;
}

function safeNormalize(connector, record) {
  try {
    return connector.normalizeProduct(record);
  } catch {
    // Let the Normalizer reject it downstream with a proper code.
    return { __normalizeError: true, raw: record };
  }
}
