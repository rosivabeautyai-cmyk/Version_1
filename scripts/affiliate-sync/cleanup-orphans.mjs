/**
 * TEMPORARY ops script — remove ORPHANED affiliate products.
 *
 * An orphan = a product with `source: 'affiliate'` AND a `storeId` that
 * no longer has a document in `affiliateStores` (its store was deleted).
 *
 * SAFETY — this can NEVER touch Awin:
 *   - Awin products are written by scripts/awin-sync/ and have NO
 *     `storeId` field and `source` is not 'affiliate'. This script only
 *     ever loads `products where source == 'affiliate'`, and then only
 *     deletes ones whose `storeId` is a non-empty string not present in
 *     the live `affiliateStores` set. Every candidate is re-checked
 *     (`source === 'affiliate'` && truthy `storeId`) immediately before
 *     deletion; anything failing that assertion is skipped and logged.
 *
 * Usage (run from scripts/affiliate-sync so firebase-admin resolves):
 *   node cleanup-orphans.mjs            # DRY RUN — lists, deletes nothing
 *   node cleanup-orphans.mjs --confirm  # actually delete
 *
 * Requires FIREBASE_SERVICE_ACCOUNT_JSON, or ../../server/serviceAccount.json.
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { initializeApp, cert, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

const HERE = dirname(fileURLToPath(import.meta.url));
const CONFIRM = process.argv.includes("--confirm");

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }
  const p = join(HERE, "..", "..", "server", "serviceAccount.json");
  return JSON.parse(readFileSync(p, "utf8"));
}

if (getApps().length === 0) {
  initializeApp({ credential: cert(loadServiceAccount()) });
}
const db = getFirestore();

async function main() {
  // 1. live store ids
  const storesSnap = await db.collection("affiliateStores").get();
  const liveStoreIds = new Set(storesSnap.docs.map((d) => d.id));
  console.log(`Live affiliate stores (${liveStoreIds.size}): ${[...liveStoreIds].join(", ") || "(none)"}\n`);

  // 2. all affiliate-sourced products
  const prodSnap = await db.collection("products").where("source", "==", "affiliate").get();

  const orphans = [];
  for (const doc of prodSnap.docs) {
    const d = doc.data();
    const sid = typeof d.storeId === "string" ? d.storeId.trim() : "";
    if (!sid) continue; // no storeId -> not a scoped affiliate product, skip
    if (liveStoreIds.has(sid)) continue; // store still exists -> not an orphan
    orphans.push({ ref: doc.ref, id: doc.id, storeId: sid, name: d.name, ext: d.externalProductId, source: d.source });
  }

  // 3. group + report
  const byStore = new Map();
  for (const o of orphans) {
    if (!byStore.has(o.storeId)) byStore.set(o.storeId, []);
    byStore.get(o.storeId).push(o);
  }

  console.log(`ORPHANED affiliate products: ${orphans.length}\n`);
  for (const [sid, list] of byStore) {
    console.log(`  storeId "${sid}"  (${list.length} products):`);
    for (const o of list) {
      console.log(`    - ${o.id}   ${o.name}  [ext:${o.ext}]`);
    }
    console.log("");
  }

  // 4. related sync logs / jobs for those orphan store ids
  const orphanStoreIds = [...byStore.keys()];
  const logHits = [];
  const jobHits = [];
  for (const sid of orphanStoreIds) {
    const l = await db.collection("affiliateSyncLogs").where("storeId", "==", sid).get();
    for (const d of l.docs) logHits.push({ ref: d.ref, id: d.id, storeId: sid });
    const j = await db.collection("affiliateSyncJobs").where("storeId", "==", sid).get();
    for (const d of j.docs) jobHits.push({ ref: d.ref, id: d.id, storeId: sid });
  }
  console.log(`affiliateSyncLogs to delete: ${logHits.length}  ${logHits.map((x) => x.id).join(", ")}`);
  console.log(`affiliateSyncJobs to delete: ${jobHits.length}  ${jobHits.map((x) => x.id).join(", ")}\n`);

  if (!CONFIRM) {
    console.log("DRY RUN — nothing deleted. Re-run with --confirm to delete the above.");
    process.exit(0);
  }

  // 5. delete (batched, with a per-doc safety re-check)
  let deletedProducts = 0;
  let skipped = 0;
  for (let i = 0; i < orphans.length; i += 400) {
    const batch = db.batch();
    for (const o of orphans.slice(i, i + 400)) {
      const fresh = await o.ref.get();
      const fd = fresh.data() || {};
      if (fd.source !== "affiliate" || !fd.storeId || liveStoreIds.has(String(fd.storeId))) {
        console.warn(`  SKIP (failed safety re-check): ${o.id}`);
        skipped += 1;
        continue;
      }
      batch.delete(o.ref);
      deletedProducts += 1;
    }
    await batch.commit();
  }
  for (const x of [...logHits, ...jobHits]) await x.ref.delete();

  console.log(`\nDeleted ${deletedProducts} orphan products (${skipped} skipped), ${logHits.length} logs, ${jobHits.length} jobs.`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
