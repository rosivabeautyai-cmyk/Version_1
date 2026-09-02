/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Resolves the PRIVATE credentials a connector needs from the backend
 * environment only. Never from Firestore, never returned to Flutter.
 *
 * Convention (so multiple stores can coexist in one environment):
 *
 *   Per-store, uppercased slug with non-alphanumerics -> "_":
 *     AFFILIATE_<SLUG>_FEED_URL
 *     AFFILIATE_<SLUG>_FEED_USERNAME      (non-secret, but kept together)
 *     AFFILIATE_<SLUG>_FEED_PASSWORD
 *     AFFILIATE_<SLUG>_FEED_TOKEN
 *     AFFILIATE_<SLUG>_API_KEY
 *     AFFILIATE_<SLUG>_API_TOKEN
 *
 *   Global fallback (handy for a single-store setup / the legacy Awin feed):
 *     AWIN_FEED_URL
 *     FEED_URL / FEED_USERNAME / FEED_PASSWORD / FEED_TOKEN
 *     API_KEY / API_TOKEN
 */

export function slugEnvKey(slug) {
  return String(slug || "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

/**
 * @param {object} store  affiliateStores document (needs `slug` or `id`)
 * @param {NodeJS.ProcessEnv} [env]
 * @return {Record<string,string>}  only keys that are actually set
 */
export function resolveStoreSecrets(store, env = process.env) {
  const slug = slugEnvKey(store.slug || store.id);
  const prefix = `AFFILIATE_${slug}_`;
  const out = {};

  const names = [
    "FEED_URL",
    "FEED_USERNAME",
    "FEED_PASSWORD",
    "FEED_SECRET",
    "FEED_TOKEN",
    "API_KEY",
    "API_TOKEN",
  ];
  for (const n of names) {
    const perStore = env[prefix + n];
    const global = env[n];
    const v = perStore || global;
    if (v) out[n] = v;
  }

  // Legacy Awin single-feed variable.
  if (env.AWIN_FEED_URL) out.AWIN_FEED_URL = env.AWIN_FEED_URL;
  if (env[prefix + "AWIN_FEED_URL"]) out.AWIN_FEED_URL = env[prefix + "AWIN_FEED_URL"];

  return out;
}
