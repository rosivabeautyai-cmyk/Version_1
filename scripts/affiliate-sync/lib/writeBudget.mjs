/**
 * Daily Firestore-write budget accounting.
 *
 * One doc per UTC day: affiliateSyncBudget/{YYYY-MM-DD} = { writesUsed, updatedAt }.
 * The engine reads it before a sync to decide whether the run fits, and
 * increments it after. This doc costs 1 read + 1 write per sync —
 * negligible against the budget it protects.
 */

import { DEFAULT_DAILY_WRITE_BUDGET, COLLECTIONS } from "./constants.mjs";

/** UTC day key, e.g. "2026-09-02". */
export function utcDayKey(d = new Date()) {
  return d.toISOString().slice(0, 10);
}

/** Resolved daily budget: env override or the safe default. */
export function dailyWriteBudget(env = process.env) {
  const n = parseInt(env.AFFILIATE_DAILY_WRITE_BUDGET ?? "", 10);
  return Number.isFinite(n) && n > 0 ? n : DEFAULT_DAILY_WRITE_BUDGET;
}

/** How many Firestore writes have been used today (0 if the doc is absent). */
export async function writesUsedToday(db, dayKey = utcDayKey()) {
  try {
    const snap = await db.collection(COLLECTIONS.SYNC_BUDGET).doc(dayKey).get();
    const v = snap.exists ? snap.data()?.writesUsed : 0;
    return Number.isFinite(v) ? v : 0;
  } catch {
    // If we can't read it, assume the worst is NOT known — return 0 and
    // let the per-batch guard + estimate do the protecting.
    return 0;
  }
}

/**
 * Best-effort increment of today's write count. Never throws.
 * @param {*} db
 * @param {number} n
 * @param {*} [FieldValue]  firebase-admin FieldValue (for `.increment`)
 * @param {string} [dayKey]
 */
export async function addWritesToday(db, n, FieldValue, dayKey = utcDayKey()) {
  if (!n || n < 1) return;
  try {
    const ref = db.collection(COLLECTIONS.SYNC_BUDGET).doc(dayKey);
    if (FieldValue && typeof FieldValue.increment === "function") {
      await ref.set(
        { writesUsed: FieldValue.increment(n), updatedAt: new Date().toISOString() },
        { merge: true },
      );
    } else {
      // Fallback (tests / no FieldValue): read-modify-write.
      const cur = await writesUsedToday(db, dayKey);
      await ref.set({ writesUsed: cur + n, updatedAt: new Date().toISOString() }, { merge: true });
    }
  } catch {
    // accounting is best-effort — a failure here must not fail the sync
  }
}
