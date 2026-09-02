/**
 * ROSIVA — daily FX-rate refresh.
 *
 * Source: https://open.er-api.com/v6/latest/USD
 *   - free, no API key, no signup, no quota on the open endpoint
 *   - refreshed once per day at source
 *   - covers every currency ROSIVA displays (EGP, SAR, AED, QAR, KWD,
 *     JOD, GBP, EUR, USD)
 *
 * What it does: for each currency below, computes `rateToUsd` = the USD
 * value of one unit of that currency (USD itself = 1) and MERGES it plus
 * `rateUpdatedAt` onto `currencies/{CODE}`. It never touches
 * admin-managed fields (symbol / names) and never touches product
 * prices — this feeds *approximate* display conversion only.
 *
 * The client (CurrencyService) ignores any rate whose `rateUpdatedAt`
 * is more than 7 days old and falls back to the original currency, so a
 * CI outage degrades safely.
 *
 * Required env: FIREBASE_SERVICE_ACCOUNT_JSON (same secret shape as the
 * other GitHub-Actions scripts).
 */

import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const SOURCE_URL = "https://open.er-api.com/v6/latest/USD";

// ISO 4217 codes ROSIVA can show prices in. Keep in sync with
// kCountryToCurrency + the CurrencyService fallback table.
const CURRENCIES = ["USD", "EGP", "SAR", "AED", "GBP", "EUR", "QAR", "KWD", "JOD"];

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not set.");
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.");
  }
}

async function fetchRates() {
  const res = await fetch(SOURCE_URL, {
    headers: { accept: "application/json" },
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`open.er-api.com HTTP ${res.status}`);
  const body = await res.json();
  if (body.result !== "success" || !body.rates || typeof body.rates !== "object") {
    throw new Error(`unexpected response: ${JSON.stringify(body).slice(0, 200)}`);
  }
  return body.rates; // { USD: 1, EGP: 49.x, ... }  (units of CODE per 1 USD)
}

async function main() {
  if (getApps().length === 0) {
    initializeApp({ credential: cert(loadServiceAccount()) });
  }
  const db = getFirestore();

  const rates = await fetchRates();

  const batch = db.batch();
  const written = [];
  const skipped = [];

  for (const code of CURRENCIES) {
    const perUsd = code === "USD" ? 1 : rates[code];
    if (!Number.isFinite(perUsd) || perUsd <= 0) {
      skipped.push(code);
      continue;
    }
    // rateToUsd = USD value of ONE unit of `code`.
    const rateToUsd = code === "USD" ? 1 : Number((1 / perUsd).toFixed(8));
    batch.set(
      db.collection("currencies").doc(code),
      {
        code,
        rateToUsd,
        rateUpdatedAt: FieldValue.serverTimestamp(),
        rateSource: "open.er-api.com",
      },
      { merge: true }, // never clobber admin-set symbol / nameEn / nameAr
    );
    written.push(`${code}=${rateToUsd}`);
  }

  if (written.length === 0) {
    throw new Error("no usable rates in the response — nothing written");
  }

  await batch.commit();
  console.log(`Updated ${written.length} currencies: ${written.join(", ")}`);
  if (skipped.length) console.warn(`Skipped (no rate in source): ${skipped.join(", ")}`);
}

main().catch((err) => {
  console.error("fx-rates update failed:", err?.message || err);
  process.exit(1);
});
