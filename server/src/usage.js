import { FieldValue } from 'firebase-admin/firestore';

import { getDb } from './firebase.js';

/**
 * Lightweight AI usage accounting. Counters ONLY — no chat content is
 * ever stored here.
 *
 *   ai_usage/{YYYY-MM-DD}            { requests, successful, failed, updatedAt }
 *   ai_user_usage/{YYYY-MM-DD__uid}  { userId, day, count, updatedAt }
 *
 * All writes go through the Admin SDK (bypasses security rules); no
 * client can touch these. Every function here is best-effort and
 * fail-open: a metrics failure must never affect an AI response.
 */

/** UTC calendar day, `YYYY-MM-DD`. */
export function dayId(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

/**
 * @param {object} opts
 * @param {boolean} opts.ok      request produced a normal 200
 * @param {string} [opts.userId] advisory per-request user id
 * @param {any} [opts._db]       test seam
 */
export async function recordAiRequest({ ok, userId, _db } = {}) {
  try {
    const db = _db || getDb();
    const day = dayId();
    const writes = [
      db.collection('ai_usage').doc(day).set(
        {
          requests: FieldValue.increment(1),
          [ok ? 'successful' : 'failed']: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
    ];
    if (userId) {
      writes.push(
        db.collection('ai_user_usage').doc(`${day}__${userId}`).set(
          {
            userId,
            day,
            count: FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
      );
    }
    await Promise.all(writes);
  } catch {
    // best-effort
  }
}

/**
 * Current-day counters for the limit check.
 * @returns {Promise<{globalRequests:number, userRequests:number}>}
 */
export async function getTodayUsage({ userId, _db } = {}) {
  try {
    const db = _db || getDb();
    const day = dayId();
    const [gSnap, uSnap] = await Promise.all([
      db.collection('ai_usage').doc(day).get(),
      userId
        ? db.collection('ai_user_usage').doc(`${day}__${userId}`).get()
        : Promise.resolve(null),
    ]);
    const g = gSnap && gSnap.exists ? gSnap.data() || {} : {};
    const u = uSnap && uSnap.exists ? uSnap.data() || {} : {};
    return {
      globalRequests: Number(g.requests) || 0,
      userRequests: Number(u.count) || 0,
    };
  } catch {
    return { globalRequests: 0, userRequests: 0 }; // fail-open
  }
}
