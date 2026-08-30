/**
 * Idempotent seed for ROSIVA's global configuration collections:
 *
 *   countries/{CODE}    — the source of truth the app reads instead of
 *                         RegionalPrefsProvider's hardcoded list
 *   currencies/{CODE}   — symbol + display name + exchange rate to USD
 *   app_config/ai       — AI enable / maintenance-mode switches the
 *                         ROSIVA AI backend enforces
 *
 * Every write is `{merge: true}` and never clears a value an admin has
 * since edited (rates, enabled flags, maintenance message). Safe to
 * re-run any time — it only fills in missing docs / missing keys.
 *
 * Exchange rates are seeded as `null` (except USD = 1). Rates are NOT
 * hardcoded here — an admin sets them in the Admin panel, or a future
 * scheduled job fills them. Until a rate exists, the app shows the
 * product's own listed price without an approximate conversion.
 *
 * Required env var (same as scripts/awin-sync):
 *   FIREBASE_SERVICE_ACCOUNT_JSON  full service-account key JSON (string)
 *
 * Usage (from scripts/seed-config/):
 *   npm install
 *   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/serviceAccount.json)" npm run seed
 */
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function initDb() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set.');
  let svc;
  try {
    svc = JSON.parse(raw);
  } catch {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.');
  }
  if (getApps().length === 0) initializeApp({ credential: cert(svc) });
  return getFirestore();
}

// Mirrors the 8 countries ROSIVA already shipped in
// RegionalPrefsProvider.countryCodes / kCountryToCurrency, plus display
// metadata the hardcoded map never had.
const CURRENCIES = [
  { code: 'USD', symbol: '$', nameEn: 'US Dollar', nameAr: 'دولار أمريكي', rateToUsd: 1 },
  { code: 'GBP', symbol: '£', nameEn: 'British Pound', nameAr: 'جنيه إسترليني', rateToUsd: null },
  { code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'يورو', rateToUsd: null },
  { code: 'EGP', symbol: 'ج.م', nameEn: 'Egyptian Pound', nameAr: 'جنيه مصري', rateToUsd: null },
  { code: 'SAR', symbol: 'ر.س', nameEn: 'Saudi Riyal', nameAr: 'ريال سعودي', rateToUsd: null },
  { code: 'AED', symbol: 'د.إ', nameEn: 'UAE Dirham', nameAr: 'درهم إماراتي', rateToUsd: null },
  { code: 'QAR', symbol: 'ر.ق', nameEn: 'Qatari Riyal', nameAr: 'ريال قطري', rateToUsd: null },
  { code: 'KWD', symbol: 'د.ك', nameEn: 'Kuwaiti Dinar', nameAr: 'دينار كويتي', rateToUsd: null },
  { code: 'JOD', symbol: 'د.أ', nameEn: 'Jordanian Dinar', nameAr: 'دينار أردني', rateToUsd: null },
];

const COUNTRIES = [
  { code: 'EG', nameEn: 'Egypt', nameAr: 'مصر', currencyCode: 'EGP', sortOrder: 1 },
  { code: 'SA', nameEn: 'Saudi Arabia', nameAr: 'السعودية', currencyCode: 'SAR', sortOrder: 2 },
  { code: 'AE', nameEn: 'United Arab Emirates', nameAr: 'الإمارات', currencyCode: 'AED', sortOrder: 3 },
  { code: 'QA', nameEn: 'Qatar', nameAr: 'قطر', currencyCode: 'QAR', sortOrder: 4 },
  { code: 'KW', nameEn: 'Kuwait', nameAr: 'الكويت', currencyCode: 'KWD', sortOrder: 5 },
  { code: 'JO', nameEn: 'Jordan', nameAr: 'الأردن', currencyCode: 'JOD', sortOrder: 6 },
  { code: 'US', nameEn: 'United States', nameAr: 'الولايات المتحدة', currencyCode: 'USD', sortOrder: 7 },
  { code: 'GB', nameEn: 'United Kingdom', nameAr: 'المملكة المتحدة', currencyCode: 'GBP', sortOrder: 8 },
];

async function seed() {
  const db = initDb();

  // currencies — fill missing docs / missing keys only.
  for (const c of CURRENCIES) {
    const ref = db.collection('currencies').doc(c.code);
    const snap = await ref.get();
    const existing = snap.exists ? snap.data() : {};
    const patch = { code: c.code };
    if (existing.symbol == null) patch.symbol = c.symbol;
    if (existing.nameEn == null) patch.nameEn = c.nameEn;
    if (existing.nameAr == null) patch.nameAr = c.nameAr;
    if (!('rateToUsd' in existing)) patch.rateToUsd = c.rateToUsd;
    if (!('rateUpdatedAt' in existing)) patch.rateUpdatedAt = null;
    await ref.set(patch, { merge: true });
    console.log(`currencies/${c.code} ${snap.exists ? 'updated' : 'created'}`);
  }

  // countries — fill missing docs / missing keys only.
  for (const c of COUNTRIES) {
    const ref = db.collection('countries').doc(c.code);
    const snap = await ref.get();
    const existing = snap.exists ? snap.data() : {};
    const patch = { countryCode: c.code };
    if (existing.nameEn == null) patch.nameEn = c.nameEn;
    if (existing.nameAr == null) patch.nameAr = c.nameAr;
    if (existing.currencyCode == null) patch.currencyCode = c.currencyCode;
    if (existing.sortOrder == null) patch.sortOrder = c.sortOrder;
    if (!('enabled' in existing)) patch.enabled = true;
    await ref.set(patch, { merge: true });
    console.log(`countries/${c.code} ${snap.exists ? 'updated' : 'created'}`);
  }

  // app_config/ai — create with safe defaults; never flip an admin's
  // choice on re-run.
  const aiRef = db.collection('app_config').doc('ai');
  const aiSnap = await aiRef.get();
  const ai = aiSnap.exists ? aiSnap.data() : {};
  const aiPatch = {};
  if (!('enabled' in ai)) aiPatch.enabled = true;
  if (!('maintenanceMode' in ai)) aiPatch.maintenanceMode = false;
  if (ai.maintenanceMessageEn == null) {
    aiPatch.maintenanceMessageEn =
      'The AI assistant is briefly down for maintenance. Please try again soon 💛';
  }
  if (ai.maintenanceMessageAr == null) {
    aiPatch.maintenanceMessageAr =
      'المساعد الذكي متوقف مؤقتًا للصيانة. جربي تاني بعد شوية 💛';
  }
  aiPatch.updatedAt = FieldValue.serverTimestamp();
  if (ai.updatedBy == null) aiPatch.updatedBy = 'seed';
  await aiRef.set(aiPatch, { merge: true });
  console.log(`app_config/ai ${aiSnap.exists ? 'updated' : 'created'}`);

  console.log('\nSeed complete.');
}

seed().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
