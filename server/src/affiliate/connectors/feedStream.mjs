/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Feed download + decompression helper, shared by the feed connectors.
 * Ported verbatim from scripts/awin-sync/awinSync.mjs (`openFeedStream`)
 * so the proven behaviour is preserved: gzip is detected from the file
 * magic bytes (0x1f 0x8b), not from headers/URL naming.
 */

import { Readable } from "node:stream";
import * as zlib from "node:zlib";

import { SyncError, ERROR_CODES } from "../lib/errors.mjs";

/**
 * @param {string} feedUrl
 * @param {object} [opts]
 * @param {Record<string,string>} [opts.headers]  e.g. Basic auth header
 * @param {number} [opts.timeoutMs]
 * @return {Promise<import('node:stream').Readable>}
 */
export async function openFeedStream(feedUrl, opts = {}) {
  const { headers = {}, timeoutMs = 60000 } = opts;
  if (!feedUrl || !/^https?:\/\//i.test(feedUrl)) {
    throw new SyncError(ERROR_CODES.INVALID_FEED_URL, "feed URL is missing or not http(s)");
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetch(feedUrl, { headers, signal: controller.signal });
  } catch (err) {
    clearTimeout(timer);
    if (err?.name === "AbortError") {
      throw new SyncError(ERROR_CODES.TIMEOUT, "feed download timed out");
    }
    throw new SyncError(ERROR_CODES.INVALID_FEED_URL, `feed download failed: ${err?.message || err}`);
  }
  clearTimeout(timer);

  if (!response.ok || !response.body) {
    if (response.status === 401 || response.status === 403) {
      throw new SyncError(ERROR_CODES.INVALID_CREDENTIALS, `feed HTTP ${response.status}`);
    }
    if (response.status === 429) {
      throw new SyncError(ERROR_CODES.RATE_LIMITED, "feed HTTP 429");
    }
    if (response.status >= 500) {
      throw new SyncError(ERROR_CODES.SERVICE_UNAVAILABLE, `feed HTTP ${response.status}`);
    }
    throw new SyncError(ERROR_CODES.INVALID_FEED_URL, `feed HTTP ${response.status}`);
  }

  const webStream = Readable.fromWeb(response.body);

  const firstChunk = await new Promise((resolve, reject) => {
    webStream.once("readable", () => {
      const chunk = webStream.read(2);
      resolve(chunk ?? Buffer.alloc(0));
    });
    webStream.once("end", () => resolve(Buffer.alloc(0)));
    webStream.once("error", reject);
  });

  const isGzip =
    firstChunk.length >= 2 && firstChunk[0] === 0x1f && firstChunk[1] === 0x8b;

  const combined = Readable.from(
    (async function* () {
      if (firstChunk.length > 0) yield firstChunk;
      for await (const chunk of webStream) yield chunk;
    })(),
  );

  return isGzip ? combined.pipe(zlib.createGunzip()) : combined;
}

/**
 * Builds an HTTP auth header from a store's feed auth config + secrets.
 * The password/secret is only ever read from `secrets` (backend env),
 * never from the store document.
 * @param {object} store
 * @param {object} secrets
 * @return {Record<string,string>}
 */
export function buildFeedAuthHeaders(store, secrets = {}) {
  const authType = (store.feedAuthType || store.authType || "none").toLowerCase();
  if (authType === "none" || !authType) return {};
  if (authType === "basic") {
    const user = store.feedUsername || secrets.FEED_USERNAME || "";
    const pass = secrets.FEED_PASSWORD || secrets.FEED_SECRET || "";
    if (!pass) {
      throw new SyncError(
        ERROR_CODES.INVALID_CREDENTIALS,
        "basic feed auth configured but no FEED_PASSWORD secret provided to the backend",
      );
    }
    const token = Buffer.from(`${user}:${pass}`).toString("base64");
    return { Authorization: `Basic ${token}` };
  }
  if (authType === "bearer" || authType === "token") {
    const token = secrets.FEED_TOKEN || secrets.FEED_SECRET || "";
    if (!token) {
      throw new SyncError(
        ERROR_CODES.INVALID_CREDENTIALS,
        "bearer feed auth configured but no FEED_TOKEN secret provided to the backend",
      );
    }
    return { Authorization: `Bearer ${token}` };
  }
  return {};
}
