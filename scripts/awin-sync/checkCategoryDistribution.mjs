/**
 * Read-only diagnostic: reports how many `products` documents exist
 * per Firestore `category` value, and prints one example doc per
 * value so you can eyeball whether it's correctly classified.
 *
 * Never writes/deletes anything. Uses the same
 * FIREBASE_SERVICE_ACCOUNT_JSON env var the sync script uses.
 *
 * Run from scripts/awin-sync/:
 *   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)" node checkCategoryDistribution.mjs
 */

import {cert, getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set."
    );
  }
  return JSON.parse(raw);
}

function initFirebase() {
  if (getApps().length === 0) {
    initializeApp({credential: cert(loadServiceAccount())});
  }
  return getFirestore();
}

async function main() {
  const db = initFirebase();
  const snapshot = await db.collection("products").get();

  console.log(`Total products: ${snapshot.size}\n`);

  const counts = new Map();
  const examples = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    // Report the RAW stored value, exactly as-is — including
    // casing/whitespace — so any inconsistency is visible rather
    // than hidden by normalizing before counting.
    const raw = data.category === undefined || data.category === null
      ? "(missing)"
      : JSON.stringify(data.category);

    counts.set(raw, (counts.get(raw) ?? 0) + 1);
    if (!examples.has(raw)) {
      examples.set(raw, {
        id: doc.id,
        name: data.name,
        brand: data.brand,
        merchantCategory: data.merchantCategory,
      });
    }
  }

  const sorted = [...counts.entries()].sort((a, b) => b[1] - a[1]);

  console.log("category value  ->  count  (example product)");
  console.log("----------------------------------------------");
  for (const [value, count] of sorted) {
    const ex = examples.get(value);
    console.log(
      `${value.padEnd(15)} -> ${String(count).padEnd(6)} ` +
        `(${ex.id}: "${ex.name}" brand=${ex.brand} merchantCategory=${JSON.stringify(ex.merchantCategory)})`
    );
  }

  const canonical = new Set(["skincare", "makeup", "perfume"]);
  const offCanon = sorted.filter(([value]) => !canonical.has(JSON.parse(value === "(missing)" ? '""' : value)));
  if (offCanon.length > 0) {
    console.log(
      "\n⚠ Non-canonical category values found (not exactly one of " +
        '"skincare"/"makeup"/"perfume") — these will NOT match the ' +
        "app's Firestore category filter until re-synced:"
    );
    for (const [value, count] of offCanon) {
      console.log(`  ${value} (${count} products)`);
    }
  } else {
    console.log("\n✓ Every product's category value is already canonical.");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
