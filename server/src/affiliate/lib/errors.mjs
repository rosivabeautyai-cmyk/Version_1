/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * Error taxonomy for the affiliate sync + Test Connection flows.
 *
 * Two audiences:
 *   - `.userMessage`  — safe, human-readable, shown in the Admin UI.
 *                       NEVER contains URLs with credentials, tokens,
 *                       passwords, or service-account detail.
 *   - `.technical`    — full detail for developer logs only.
 */

export const ERROR_CODES = Object.freeze({
  INVALID_CONFIG: "invalid_config",
  INVALID_FEED_URL: "invalid_feed_url",
  INVALID_CREDENTIALS: "invalid_credentials",
  UNAUTHORIZED: "unauthorized",
  RATE_LIMITED: "rate_limited",
  TIMEOUT: "timeout",
  MALFORMED_PRODUCT: "malformed_product",
  MISSING_PRODUCT_ID: "missing_product_id",
  MISSING_PRODUCT_NAME: "missing_product_name",
  MISSING_PRODUCT_URL: "missing_product_url",
  INVALID_PRICE: "invalid_price",
  DUPLICATE_PRODUCT: "duplicate_product",
  EMPTY_FEED: "empty_feed",
  CATALOG_DROP: "catalog_drop",
  SERVICE_UNAVAILABLE: "service_unavailable",
  NOT_SUPPORTED: "not_supported",
  DATA_SOURCE_REQUIRED: "data_source_required",
  UNKNOWN: "unknown",
});

const DEFAULT_USER_MESSAGES = {
  [ERROR_CODES.INVALID_CONFIG]: "The store configuration is incomplete or invalid.",
  [ERROR_CODES.INVALID_FEED_URL]: "The product feed URL is missing or not reachable.",
  [ERROR_CODES.INVALID_CREDENTIALS]: "The stored credentials were rejected by the source.",
  [ERROR_CODES.UNAUTHORIZED]: "Access to the product source was denied.",
  [ERROR_CODES.RATE_LIMITED]: "The product source is rate-limiting requests. Try again later.",
  [ERROR_CODES.TIMEOUT]: "The product source did not respond in time.",
  [ERROR_CODES.MALFORMED_PRODUCT]: "Some products in the source could not be read.",
  [ERROR_CODES.MISSING_PRODUCT_ID]: "A product was skipped because it had no unique ID.",
  [ERROR_CODES.MISSING_PRODUCT_NAME]: "A product was skipped because it had no name.",
  [ERROR_CODES.MISSING_PRODUCT_URL]: "A product was skipped because it had no product URL.",
  [ERROR_CODES.INVALID_PRICE]: "A product was skipped because of an invalid price.",
  [ERROR_CODES.DUPLICATE_PRODUCT]: "A duplicate product was ignored.",
  [ERROR_CODES.EMPTY_FEED]:
    "The product source returned zero products. Nothing was deactivated — the existing catalog was left untouched. Check the feed/API before the next sync.",
  [ERROR_CODES.CATALOG_DROP]:
    "The product source returned far fewer products than expected, so no products were deactivated. Review the source, then re-run the sync to apply changes.",
  [ERROR_CODES.SERVICE_UNAVAILABLE]: "The product source is currently unavailable.",
  [ERROR_CODES.NOT_SUPPORTED]: "This integration type does not support automatic import.",
  [ERROR_CODES.DATA_SOURCE_REQUIRED]:
    "Product data source required. Configure a product feed, REST API, or affiliate-network feed for this store.",
  [ERROR_CODES.UNKNOWN]: "The operation failed. Check the sync history for details.",
};

export class SyncError extends Error {
  /**
   * @param {string} code   one of ERROR_CODES
   * @param {string} [technical]  developer-only detail
   * @param {string} [userMessage] override the default safe message
   */
  constructor(code, technical, userMessage) {
    super(userMessage || DEFAULT_USER_MESSAGES[code] || DEFAULT_USER_MESSAGES.unknown);
    this.name = "SyncError";
    this.code = ERROR_CODES[code?.toUpperCase?.()] ? code : (Object.values(ERROR_CODES).includes(code) ? code : ERROR_CODES.UNKNOWN);
    this.userMessage = userMessage || DEFAULT_USER_MESSAGES[this.code] || DEFAULT_USER_MESSAGES.unknown;
    this.technical = technical || this.message;
  }
}

/**
 * Redacts anything that looks like a secret from a string before it is
 * logged or returned. Best-effort defense-in-depth — secrets should
 * never reach here in the first place.
 * @param {string} input
 * @return {string}
 */
export function redact(input) {
  if (!input) return "";
  let s = String(input);
  // URL credentials  https://user:pass@host  ->  https://***@host
  s = s.replace(/(https?:\/\/)[^/@\s]+:[^/@\s]+@/gi, "$1***@");
  // query params that look sensitive
  s = s.replace(
    /([?&](?:password|passwd|pwd|secret|token|apikey|api_key|key|auth|signature)=)[^&\s]+/gi,
    "$1***",
  );
  // long hex / base64 blobs (service account fragments, tokens)
  s = s.replace(/[A-Za-z0-9_-]{40,}/g, "***");
  return s;
}

/**
 * Maps an arbitrary thrown value to a { code, userMessage, technical }
 * shape that is safe to return to the Admin UI.
 * @param {unknown} err
 * @return {{ code: string, userMessage: string, technical: string }}
 */
export function toSafeError(err) {
  if (err instanceof SyncError) {
    return { code: err.code, userMessage: err.userMessage, technical: redact(err.technical) };
  }
  const raw = err instanceof Error ? err.message : String(err);
  const lower = raw.toLowerCase();
  let code = ERROR_CODES.UNKNOWN;
  if (lower.includes("timeout") || lower.includes("etimedout") || lower.includes("abort")) {
    code = ERROR_CODES.TIMEOUT;
  } else if (lower.includes("429") || lower.includes("rate limit")) {
    code = ERROR_CODES.RATE_LIMITED;
  } else if (lower.includes("401") || lower.includes("403") || lower.includes("unauthor")) {
    code = ERROR_CODES.UNAUTHORIZED;
  } else if (lower.includes("enotfound") || lower.includes("econnrefused") || lower.includes("dns")) {
    code = ERROR_CODES.INVALID_FEED_URL;
  } else if (lower.includes("5") && lower.includes("http")) {
    code = ERROR_CODES.SERVICE_UNAVAILABLE;
  }
  return {
    code,
    userMessage: DEFAULT_USER_MESSAGES[code],
    technical: redact(raw),
  };
}
