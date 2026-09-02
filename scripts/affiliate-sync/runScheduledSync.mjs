/**
 * Entry point for the scheduled multi-store sync (GitHub Actions —
 * .github/workflows/affiliate-sync.yml) and for a manual one-off run.
 *
 * Usage:
 *   node runScheduledSync.mjs                 # sync every store that is due
 *   node runScheduledSync.mjs --all           # sync every active store now
 *   node runScheduledSync.mjs --store <id>    # sync one store now
 *   node runScheduledSync.mjs --drain-jobs    # only process affiliateSyncJobs queue
 *
 * A store is "due" when: status == active, syncEnabled != false, and
 * (nextSyncAt is null/past). After a run, nextSyncAt is set from the
 * store's syncFrequency, so the fixed 6-hourly cron naturally spaces
 * out 12h / daily / weekly stores too.
 *
 * The affiliateSyncJobs queue lets the Admin "Sync Now" button enqueue
 * a run without blocking the UI on a large feed — this worker drains it.
 */

import { initFirebase } from "./lib/firestore.mjs";
import { syncAffiliateStore } from "./syncEngine.mjs";
import { COLLECTIONS, STORE_STATUS, TRIGGERED_BY, SYNC_STATUS } from "./lib/constants.mjs";
import { redact } from "./lib/errors.mjs";

function parseArgs(argv) {
  const args = { all: false, drainJobs: false, storeId: null };
  for (let i = 2; i < argv.length; i += 1) {
    if (argv[i] === "--all") args.all = true;
    else if (argv[i] === "--drain-jobs") args.drainJobs = true;
    else if (argv[i] === "--store") args.storeId = argv[++i];
  }
  return args;
}

function isDue(store, nowMs) {
  if ((store.status || STORE_STATUS.ACTIVE) !== STORE_STATUS.ACTIVE) return false;
  if (store.syncEnabled === false) return false;
  if (!store.nextSyncAt) return true;
  const t = Date.parse(store.nextSyncAt);
  return Number.isFinite(t) ? t <= nowMs : true;
}

async function drainJobs(db) {
  const snap = await db
    .collection(COLLECTIONS.SYNC_JOBS)
    .where("status", "==", "queued")
    .get();
  const results = [];
  for (const jobDoc of snap.docs) {
    const job = jobDoc.data();
    await jobDoc.ref.set({ status: "running", startedAt: new Date().toISOString() }, { merge: true });
    try {
      const log = await syncAffiliateStore({
        db,
        storeId: job.storeId,
        triggeredBy: TRIGGERED_BY.ADMIN,
        force: true,
      });
      await jobDoc.ref.set(
        { status: log.status === "error" ? "error" : "done", finishedAt: new Date().toISOString(), logId: log.id },
        { merge: true },
      );
      results.push({ storeId: job.storeId, status: log.status });
    } catch (err) {
      await jobDoc.ref.set(
        { status: "error", finishedAt: new Date().toISOString(), error: redact(String(err?.message || err)) },
        { merge: true },
      );
      results.push({ storeId: job.storeId, status: "error" });
    }
  }
  return results;
}

async function main() {
  const args = parseArgs(process.argv);
  const db = initFirebase();
  const summary = [];

  // Always drain the on-demand queue first.
  const jobResults = await drainJobs(db);
  summary.push(...jobResults.map((r) => ({ ...r, via: "job" })));

  if (args.drainJobs) {
    console.log(JSON.stringify({ summary }, null, 2));
    return;
  }

  let storeIds = [];
  if (args.storeId) {
    storeIds = [args.storeId];
  } else {
    const snap = await db.collection(COLLECTIONS.STORES).get();
    const nowMs = Date.now();
    for (const d of snap.docs) {
      const store = { id: d.id, ...d.data() };
      if (args.all ? (store.status || STORE_STATUS.ACTIVE) === STORE_STATUS.ACTIVE : isDue(store, nowMs)) {
        // don't double-run something the job queue just handled
        if (!jobResults.some((r) => r.storeId === store.id)) storeIds.push(store.id);
      }
    }
  }

  for (const id of storeIds) {
    try {
      const log = await syncAffiliateStore({
        db,
        storeId: id,
        triggeredBy: args.storeId ? TRIGGERED_BY.ADMIN : TRIGGERED_BY.SCHEDULED,
        force: Boolean(args.storeId),
      });
      summary.push({
        storeId: id,
        via: "schedule",
        status: log.status,
        new: log.newProducts,
        updated: log.updatedProducts,
        deactivated: log.deactivatedProducts,
        failed: log.failedProducts,
      });
    } catch (err) {
      summary.push({ storeId: id, via: "schedule", status: "error", error: redact(String(err?.message || err)) });
    }
  }

  console.log(JSON.stringify({ syncedStores: storeIds.length, summary }, null, 2));

  const anyError = summary.some((s) => s.status === "error");
  process.exit(anyError ? 1 : 0);
}

main().catch((err) => {
  console.error("[affiliate-sync] fatal:", redact(String(err?.stack || err)));
  process.exit(1);
});

export { isDue };
