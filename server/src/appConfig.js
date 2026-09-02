import { getDb } from './firebase.js';

/**
 * Reads the admin-controlled `app_config/ai` document and caches it
 * briefly. The ROSIVA AI backend is the ENFORCEMENT point for the AI
 * on/off and maintenance switches — the Flutter client only mirrors
 * them for a friendlier banner.
 *
 * Fail-open for enabled / maintenanceMode: if the document is missing,
 * malformed, or Firestore is unreachable, the assistant stays ENABLED.
 * A config read must never be able to take the assistant down.
 *
 * Fail-CLOSED for dailyGlobalLimit: it is NEVER null. If the document
 * doesn't set it (or can't be read) a finite fallback still applies, so
 * a single abusive account can't run the Groq / Firestore bill up
 * without bound. Admins raise the ceiling from the dashboard (or via
 * AI_DAILY_GLOBAL_LIMIT_FALLBACK) as real traffic grows; there is
 * deliberately no "unlimited" setting.
 */

/** Fail-closed backstop for the daily global request cap. */
export const GLOBAL_LIMIT_FALLBACK = (() => {
  const n = Number(process.env.AI_DAILY_GLOBAL_LIMIT_FALLBACK);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 5000;
})();

const DEFAULT = Object.freeze({
  enabled: true,
  maintenanceMode: false,
  maintenanceMessageEn: '',
  maintenanceMessageAr: '',
  dailyGlobalLimit: GLOBAL_LIMIT_FALLBACK,
  dailyUserLimit: null,
});

function posIntOrNull(v) {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : null;
}

const CACHE_TTL_MS = 60_000;

let cache = { value: DEFAULT, at: 0 };

/**
 * @param {object} [opts]
 * @param {() => any} [opts._db]   test seam
 * @param {boolean} [opts.force]   bypass the cache
 * @returns {Promise<{enabled:boolean, maintenanceMode:boolean, maintenanceMessageEn:string, maintenanceMessageAr:string}>}
 */
export async function getAiConfig({ _db, force = false } = {}) {
  const now = Date.now();
  if (!force && now - cache.at < CACHE_TTL_MS) return cache.value;

  try {
    const db = _db || getDb();
    const snap = await db.collection('app_config').doc('ai').get();
    if (!snap || !snap.exists) {
      cache = { value: DEFAULT, at: now };
      return DEFAULT;
    }
    const d = (typeof snap.data === 'function' ? snap.data() : snap.data) || {};
    const value = {
      enabled: d.enabled !== false, // default true
      maintenanceMode: d.maintenanceMode === true, // default false
      maintenanceMessageEn:
        typeof d.maintenanceMessageEn === 'string' ? d.maintenanceMessageEn : '',
      maintenanceMessageAr:
        typeof d.maintenanceMessageAr === 'string' ? d.maintenanceMessageAr : '',
      // Explicit doc value wins; absence / invalid -> fail-closed fallback.
      dailyGlobalLimit: posIntOrNull(d.dailyGlobalLimit) ?? GLOBAL_LIMIT_FALLBACK,
      dailyUserLimit: posIntOrNull(d.dailyUserLimit),
    };
    cache = { value, at: now };
    return value;
  } catch {
    // Fail-open — never let a config read break the assistant.
    cache = { value: DEFAULT, at: now };
    return DEFAULT;
  }
}

/** Test helper. */
export function __resetAiConfigCache() {
  cache = { value: DEFAULT, at: 0 };
}
