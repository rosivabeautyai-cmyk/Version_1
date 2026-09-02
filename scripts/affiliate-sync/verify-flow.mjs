/**
 * TEMPORARY verification script — NOT part of the product.
 * Delete it when done:  rm scripts/verify-affiliate-flow.mjs
 *
 * Exercises the backend half of the affiliate flow end to end, against
 * the LIVE Render backend and the REAL Firestore project:
 *
 *   mint admin ID token  ->  create affiliateStores/mock-verify (mock)
 *   ->  POST /test-connection  ->  POST /sync
 *   ->  read back products + sync log + store doc
 *
 * Requires server/serviceAccount.json (gitignored, already on disk).
 * Reads the PUBLIC web API key from lib/firebase_options.dart.
 *
 * Run from repo root:
 *   node --experimental-vm-modules scripts/affiliate-sync/node_modules/.bin/... (no)
 * Run it so firebase-admin resolves (it lives in scripts/affiliate-sync/node_modules):
 *   cd scripts/affiliate-sync && node verify-flow.mjs
 * or:
 *   cd server && node ../scripts/verify-affiliate-flow.mjs
 *
 * Flags:
 *   --url=https://...     override the backend base URL
 *   --cleanup            delete the mock store, its products, its sync
 *                        logs/jobs, and the throwaway auth user, then exit
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { initializeApp, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..", "..");
const SA_PATH = join(ROOT, "server", "serviceAccount.json");
const OPTS_PATH = join(ROOT, "lib", "firebase_options.dart");

const arg = (p) => process.argv.find((a) => a.startsWith(p));
const RENDER_URL = (arg("--url=")?.slice(6) || "https://version-1-yhjf.onrender.com").replace(/\/+$/, "");
const CLEANUP = process.argv.includes("--cleanup");

const STORE_ID = "mock-verify";
const BOT_UID = "affiliate-verify-bot";

function die(msg, err) {
  console.error(`\nFATAL: ${msg}`);
  if (err) console.error(err.stack || err);
  process.exit(1);
}

let sa;
try {
  sa = JSON.parse(readFileSync(SA_PATH, "utf8"));
} catch (e) {
  die(`could not read/parse ${SA_PATH}`, e);
}
initializeApp({ credential: cert(sa) });
const auth = getAuth();
const db = getFirestore();

let WEB_API_KEY;
try {
  WEB_API_KEY = /apiKey:\s*'([^']+)'/.exec(readFileSync(OPTS_PATH, "utf8"))[1];
} catch (e) {
  die("could not extract web apiKey from lib/firebase_options.dart", e);
}

async function mintIdToken() {
  const customToken = await auth.createCustomToken(BOT_UID, { admin: true, role: "admin" });
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${WEB_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  );
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(`signInWithCustomToken HTTP ${res.status}: ${JSON.stringify(body)}`);
  }
  return body.idToken;
}

async function post(path, idToken, payload) {
  const res = await fetch(`${RENDER_URL}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${idToken}` },
    body: JSON.stringify(payload ?? {}),
  });
  let body;
  const text = await res.text();
  try {
    body = JSON.parse(text);
  } catch {
    body = { __rawText: text };
  }
  return { status: res.status, body };
}

async function cleanup() {
  console.log(`Cleanup: deleting mock store + products + logs/jobs for "${STORE_ID}" ...`);
  const prod = await db.collection("products").where("storeId", "==", STORE_ID).get();
  let n = 0;
  for (let i = 0; i < prod.docs.length; i += 400) {
    const b = db.batch();
    for (const d of prod.docs.slice(i, i + 400)) b.delete(d.ref);
    await b.commit();
    n += Math.min(400, prod.docs.length - i);
  }
  console.log(`  deleted ${n} product docs`);

  for (const col of ["affiliateSyncLogs", "affiliateSyncJobs"]) {
    const s = await db.collection(col).where("storeId", "==", STORE_ID).get();
    for (const d of s.docs) await d.ref.delete();
    console.log(`  deleted ${s.size} ${col} docs`);
  }

  await db.collection("affiliateStores").doc(STORE_ID).delete();
  console.log(`  deleted affiliateStores/${STORE_ID}`);

  try {
    await auth.deleteUser(BOT_UID);
    console.log(`  deleted auth user ${BOT_UID}`);
  } catch (e) {
    console.log(`  auth user ${BOT_UID}: ${e.code || e.message}`);
  }
  console.log("Cleanup done.");
}

async function main() {
  if (CLEANUP) {
    await cleanup();
    return;
  }

  console.log(`Backend: ${RENDER_URL}`);
  console.log(`Project: ${sa.project_id}\n`);

  // 0. warm the free-tier instance (cold start can take ~30-60s)
  process.stdout.write("Warming /health ... ");
  try {
    const h = await fetch(`${RENDER_URL}/health`);
    console.log(`${h.status} ${JSON.stringify(await h.json())}`);
  } catch (e) {
    console.log(`(warmup failed, continuing) ${e.message}`);
  }

  // 1. mint admin ID token
  process.stdout.write("\n[1] Minting admin ID token ... ");
  let idToken;
  try {
    idToken = await mintIdToken();
    console.log(`ok (uid=${BOT_UID}, admin claim, token length ${idToken.length})`);
  } catch (e) {
    die("could not mint an ID token", e);
  }

  // 2. create the mock store
  process.stdout.write("[2] Writing affiliateStores/mock-verify ... ");
  await db.collection("affiliateStores").doc(STORE_ID).set(
    {
      name: "Mock Verify Store",
      slug: STORE_ID,
      currency: "USD",
      integrationType: "mock",
      affiliateNetwork: "mock",
      defaultCommissionRate: 8,
      commissionType: "percentage",
      status: "active",
      syncEnabled: true,
      syncFrequency: "daily",
      syncStatus: "idle",
      productCount: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log("ok");

  // 3. test-connection
  console.log("\n[3] POST /api/admin/affiliate-stores/mock-verify/test-connection");
  const tc = await post(`/api/admin/affiliate-stores/${STORE_ID}/test-connection`, idToken, {});
  console.log(`    HTTP ${tc.status}`);
  console.log(JSON.stringify(tc.body, null, 2));

  // 4. sync
  console.log("\n[4] POST /api/admin/affiliate-stores/mock-verify/sync  {mode:'auto'}");
  const sy = await post(`/api/admin/affiliate-stores/${STORE_ID}/sync`, idToken, { mode: "auto" });
  console.log(`    HTTP ${sy.status}`);
  console.log(JSON.stringify(sy.body, null, 2));

  // give any async write a beat
  await new Promise((r) => setTimeout(r, 1500));

  // 5. read back products
  console.log("\n[5] Firestore: products where storeId == 'mock-verify'");
  const prod = await db.collection("products").where("storeId", "==", STORE_ID).get();
  console.log(`    count: ${prod.size}`);
  console.log(`    doc ids: ${JSON.stringify(prod.docs.map((d) => d.id))}`);
  if (!prod.empty) {
    const d = prod.docs[0];
    const s = d.data();
    console.log(`    sample doc "${d.id}":`);
    console.log(
      JSON.stringify(
        {
          storeId: s.storeId,
          externalProductId: s.externalProductId,
          source: s.source,
          isRosivaProduct: s.isRosivaProduct,
          isActive: s.isActive,
          active: s.active,
          rosivaCategory: s.rosivaCategory,
          name: s.name,
          price: s.price,
          currency: s.currency,
          commissionRate: s.commissionRate,
          affiliateUrl: s.affiliateUrl,
          storeUrl: s.storeUrl,
        },
        null,
        2,
      ),
    );
  }

  // 6. sync log
  console.log("\n[6] Firestore: affiliateSyncLogs where storeId == 'mock-verify'");
  const logSnap = await db.collection("affiliateSyncLogs").where("storeId", "==", STORE_ID).get();
  const logs = logSnap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .sort((a, b) => String(b.startedAt).localeCompare(String(a.startedAt)));
  console.log(`    total logs for this store: ${logs.length}`);
  console.log("    latest:");
  console.log(JSON.stringify(logs[0] ?? null, null, 2));

  // store doc after
  console.log("\n[7] Firestore: affiliateStores/mock-verify AFTER");
  const storeAfter = (await db.collection("affiliateStores").doc(STORE_ID).get()).data();
  console.log(JSON.stringify(storeAfter, null, 2));

  console.log(
    "\nDONE. To remove everything this created:\n" +
      "  cd scripts/affiliate-sync && node verify-flow.mjs --cleanup\n",
  );
}

main().then(
  () => process.exit(0),
  (e) => die("unhandled", e),
);
