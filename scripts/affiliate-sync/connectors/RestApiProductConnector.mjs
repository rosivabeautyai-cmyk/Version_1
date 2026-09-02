/**
 * RestApiProductConnector — configuration-driven generic REST connector.
 *
 * It does NOT assume any specific third-party API. Everything about the
 * request/response shape is declared on the affiliateStores document:
 *
 *   integrationType: "rest_api"
 *   apiBaseUrl:      "https://api.example.com/v2"
 *   apiProductsPath: "/products"                 (appended to apiBaseUrl)
 *   apiAuthType:     "none" | "bearer" | "header" | "query"
 *   apiAuthHeaderName: "X-Api-Key"               (apiAuthType === "header")
 *   apiAuthQueryParam: "api_key"                 (apiAuthType === "query")
 *   publicApiId:     "pub-12345"                 (a NON-secret identifier, if the API needs one in the URL)
 *   apiPagination: {
 *     style: "page" | "offset" | "cursor",
 *     pageParam: "page", sizeParam: "limit", pageSize: 100,
 *     offsetParam: "offset",
 *     cursorParam: "cursor", cursorPath: "meta.next_cursor",
 *     totalPath: "meta.total"
 *   }
 *   apiItemsPath:   "data"                       (array of items in the response)
 *   fieldMap: { externalProductId: "id", name: "title", ... }
 *
 * The API KEY / token itself is a SECRET: it is read from `secrets`
 * (backend env var `AFFILIATE_<SLUG>_API_KEY`) and never stored on the
 * document or sent to Flutter.
 *
 * If required config is missing this connector fails fast with a safe
 * "invalid config" error rather than inventing behaviour.
 */

import { ProductConnector } from "./ProductConnector.mjs";
import { SyncError, ERROR_CODES, toSafeError } from "../lib/errors.mjs";
import { detectColumns } from "../lib/detectColumns.mjs";

function getPath(obj, path) {
  if (!path) return undefined;
  return path.split(".").reduce((acc, k) => (acc == null ? acc : acc[k]), obj);
}

export class RestApiProductConnector extends ProductConnector {
  constructor(store, secrets = {}, opts = {}) {
    super(store, secrets);
    this.baseUrl = (store.apiBaseUrl || "").replace(/\/+$/, "");
    this.productsPath = store.apiProductsPath || "/products";
    this.authType = (store.apiAuthType || "none").toLowerCase();
    this.pag = store.apiPagination || { style: "page", pageParam: "page", sizeParam: "limit", pageSize: 100 };
    this.itemsPath = store.apiItemsPath || "data";
    this.fieldMap = store.fieldMap || {};
    this.apiKey = secrets.API_KEY || secrets.API_TOKEN || "";
    this.timeoutMs = opts.timeoutMs || 30000;
    this.maxPages = opts.maxPages || 10000;
  }

  _assertConfigured() {
    if (!this.baseUrl || !/^https?:\/\//i.test(this.baseUrl)) {
      throw new SyncError(ERROR_CODES.INVALID_CONFIG, "apiBaseUrl is missing or not http(s)");
    }
    if (!this.fieldMap.externalProductId || !this.fieldMap.name) {
      throw new SyncError(
        ERROR_CODES.INVALID_CONFIG,
        "fieldMap must at least map externalProductId and name",
      );
    }
    if (this.authType !== "none" && !this.apiKey) {
      throw new SyncError(
        ERROR_CODES.INVALID_CREDENTIALS,
        `apiAuthType is "${this.authType}" but no API key secret was provided to the backend`,
      );
    }
  }

  _buildUrl(pageState) {
    const url = new URL(this.baseUrl + this.productsPath);
    if (this.store.publicApiId) url.searchParams.set("id", this.store.publicApiId);
    const p = this.pag;
    if (p.style === "offset") {
      url.searchParams.set(p.offsetParam || "offset", String(pageState.offset || 0));
      if (p.sizeParam) url.searchParams.set(p.sizeParam, String(p.pageSize || 100));
    } else if (p.style === "cursor") {
      if (pageState.cursor) url.searchParams.set(p.cursorParam || "cursor", pageState.cursor);
      if (p.sizeParam) url.searchParams.set(p.sizeParam, String(p.pageSize || 100));
    } else {
      url.searchParams.set(p.pageParam || "page", String(pageState.page || 1));
      if (p.sizeParam) url.searchParams.set(p.sizeParam, String(p.pageSize || 100));
    }
    if (this.authType === "query") {
      url.searchParams.set(this.store.apiAuthQueryParam || "api_key", this.apiKey);
    }
    return url.toString();
  }

  _headers() {
    const h = { Accept: "application/json" };
    if (this.authType === "bearer") h.Authorization = `Bearer ${this.apiKey}`;
    else if (this.authType === "header") h[this.store.apiAuthHeaderName || "X-Api-Key"] = this.apiKey;
    return h;
  }

  async _fetchJson(url) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    let res;
    try {
      res = await fetch(url, { headers: this._headers(), signal: controller.signal });
    } catch (err) {
      clearTimeout(timer);
      if (err?.name === "AbortError") throw new SyncError(ERROR_CODES.TIMEOUT, "API request timed out");
      throw new SyncError(ERROR_CODES.SERVICE_UNAVAILABLE, `API request failed: ${err?.message || err}`);
    }
    clearTimeout(timer);
    if (res.status === 401 || res.status === 403) {
      throw new SyncError(ERROR_CODES.INVALID_CREDENTIALS, `API HTTP ${res.status}`);
    }
    if (res.status === 429) throw new SyncError(ERROR_CODES.RATE_LIMITED, "API HTTP 429");
    if (res.status >= 500) throw new SyncError(ERROR_CODES.SERVICE_UNAVAILABLE, `API HTTP ${res.status}`);
    if (!res.ok) throw new SyncError(ERROR_CODES.SERVICE_UNAVAILABLE, `API HTTP ${res.status}`);
    try {
      return await res.json();
    } catch (err) {
      throw new SyncError(ERROR_CODES.MALFORMED_PRODUCT, `API response is not JSON: ${err.message}`);
    }
  }

  normalizeProduct(record) {
    const pick = (key) => {
      const col = this.fieldMap[key];
      if (!col) return undefined;
      return col.includes(".") ? getPath(record, col) : record[col];
    };
    const raw = {
      externalProductId: pick("externalProductId"),
      name: pick("name"),
      description: pick("description"),
      brand: pick("brand"),
      categoryName: pick("categoryName"),
      price: pick("price"),
      oldPrice: pick("oldPrice"),
      salePrice: pick("salePrice"),
      currency: pick("currency"),
      imageUrl: pick("imageUrl"),
      productUrl: pick("productUrl"),
      affiliateUrl: pick("affiliateUrl"),
      availability: pick("availability"),
      rating: pick("rating"),
      reviewCount: pick("reviewCount"),
      commissionRate: pick("commissionRate"),
      updatedAt: pick("updatedAt"),
    };
    raw.affiliateUrl = raw.affiliateUrl || this.buildAffiliateUrl(raw);
    return raw;
  }

  async estimateProductCount() {
    try {
      this._assertConfigured();
      const body = await this._fetchJson(this._buildUrl({ page: 1, offset: 0 }));
      const total = getPath(body, this.pag.totalPath || "meta.total");
      if (Number.isFinite(total)) return total;
      // No total in the response — fall back to the streaming count.
      return super.estimateProductCount();
    } catch {
      return null;
    }
  }

  async testConnection() {
    try {
      this._assertConfigured();
      const body = await this._fetchJson(this._buildUrl({ page: 1, offset: 0 }));
      const items = getPath(body, this.itemsPath);
      const arr = Array.isArray(items) ? items : Array.isArray(body) ? body : [];
      const total = getPath(body, this.pag.totalPath);
      // RAW API items (not normalized) so the orchestrator normalizes
      // once and the Admin UI sees the real field names for auto-mapping.
      const sample = arr.slice(0, 5);
      return {
        ok: arr.length > 0,
        productsDetected: Number.isFinite(total) ? total : arr.length || null,
        sample,
        detectedColumns: detectColumns(sample),
        error:
          arr.length === 0
            ? {
                code: ERROR_CODES.MALFORMED_PRODUCT,
                userMessage: "Connected to the API, but no products were found at the configured items path.",
                technical: `no array at apiItemsPath="${this.itemsPath}"`,
              }
            : undefined,
      };
    } catch (err) {
      return { ok: false, productsDetected: null, sample: [], detectedColumns: [], error: toSafeError(err) };
    }
  }

  async *fetchProductPages() {
    this._assertConfigured();
    const p = this.pag;
    let page = 1;
    let offset = 0;
    let cursor = null;
    let pagesSeen = 0;

    while (pagesSeen < this.maxPages) {
      const body = await this._fetchJson(this._buildUrl({ page, offset, cursor }));
      const items = getPath(body, this.itemsPath);
      const arr = Array.isArray(items) ? items : Array.isArray(body) ? body : [];
      if (arr.length === 0) return;

      yield arr.map((r) => this.normalizeProduct(r));
      pagesSeen += 1;

      if (p.style === "cursor") {
        const next = getPath(body, p.cursorPath || "meta.next_cursor");
        if (!next || next === cursor) return;
        cursor = next;
      } else if (p.style === "offset") {
        offset += arr.length;
        if (arr.length < (p.pageSize || 100)) return;
      } else {
        page += 1;
        if (arr.length < (p.pageSize || 100)) return;
      }
    }
  }
}
