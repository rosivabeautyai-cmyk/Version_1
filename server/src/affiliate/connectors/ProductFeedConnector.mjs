/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * ProductFeedConnector — generic downloadable product feed (CSV / XML /
 * JSON). Configuration-driven: it does NOT assume any single retailer's
 * schema. A `fieldMap` on the store maps ROSIVA raw-product keys to the
 * column / element / property names used by that feed.
 *
 * Store config (affiliateStores document), all public, no secrets:
 *   integrationType: "product_feed"
 *   feedUrl:        "https://.../feed.csv.gz"
 *   feedFormat:     "csv" | "xml" | "json"
 *   feedItemPath:   (xml/json) e.g. "products.product" or "items"
 *   feedAuthType:   "none" | "basic" | "bearer"
 *   feedUsername:   (basic) username — password comes from a backend secret
 *   fieldMap: {
 *     externalProductId: "sku",
 *     name: "title",
 *     description: "desc",
 *     brand: "brand",
 *     categoryName: "category",
 *     price: "price",
 *     oldPrice: "rrp",
 *     currency: "currency",
 *     imageUrl: "image",
 *     productUrl: "link",
 *     affiliateUrl: "aw_deep_link",
 *     availability: "in_stock",
 *     rating: "rating",
 *     commissionRate: "commission"
 *   }
 *
 * Private feed credentials (FEED_PASSWORD / FEED_TOKEN) are passed in
 * via `secrets` from the backend environment — never from Firestore,
 * never to Flutter.
 */

import { ProductConnector } from "./ProductConnector.mjs";
import { openFeedStream, buildFeedAuthHeaders } from "./feedStream.mjs";
import { SyncError, ERROR_CODES, toSafeError } from "../lib/errors.mjs";
import { FEED_FORMATS } from "../lib/constants.mjs";

const DEFAULT_FIELD_MAP = {
  externalProductId: "id",
  name: "name",
  description: "description",
  brand: "brand",
  categoryName: "category",
  price: "price",
  oldPrice: "rrp_price",
  salePrice: "sale_price",
  currency: "currency",
  imageUrl: "image_url",
  productUrl: "url",
  affiliateUrl: "deep_link",
  availability: "in_stock",
  rating: "rating",
  reviewCount: "reviews",
  commissionRate: "commission",
};

export class ProductFeedConnector extends ProductConnector {
  constructor(store, secrets = {}, opts = {}) {
    super(store, secrets);
    this.format = (store.feedFormat || "csv").toLowerCase();
    this.fieldMap = { ...DEFAULT_FIELD_MAP, ...(store.fieldMap || {}) };
    this.pageSize = opts.pageSize || 500;
    this.timeoutMs = opts.timeoutMs || 60000;
  }

  _authHeaders() {
    return buildFeedAuthHeaders(this.store, this.secrets);
  }

  _pick(record, key) {
    const col = this.fieldMap[key];
    if (!col) return undefined;
    // support "a.b.c" dotted paths for xml/json records
    if (col.includes(".")) {
      return col.split(".").reduce((acc, k) => (acc == null ? acc : acc[k]), record);
    }
    return record[col];
  }

  normalizeProduct(record) {
    const raw = {
      externalProductId: this._pick(record, "externalProductId"),
      name: this._pick(record, "name"),
      description: this._pick(record, "description"),
      brand: this._pick(record, "brand"),
      categoryName: this._pick(record, "categoryName"),
      price: this._pick(record, "price"),
      oldPrice: this._pick(record, "oldPrice"),
      salePrice: this._pick(record, "salePrice"),
      currency: this._pick(record, "currency"),
      imageUrl: this._pick(record, "imageUrl"),
      productUrl: this._pick(record, "productUrl"),
      affiliateUrl: this._pick(record, "affiliateUrl"),
      availability: this._pick(record, "availability"),
      rating: this._pick(record, "rating"),
      reviewCount: this._pick(record, "reviewCount"),
      commissionRate: this._pick(record, "commissionRate"),
      updatedAt: record.last_updated || record.updated_at || null,
    };
    raw.affiliateUrl = raw.affiliateUrl || this.buildAffiliateUrl(raw);
    return raw;
  }

  async testConnection() {
    try {
      const sample = [];
      let count = 0;
      for await (const page of this.fetchProductPages({ sampleLimit: 5 })) {
        for (const rec of page) {
          count += 1;
          if (sample.length < 5) sample.push(rec);
        }
        if (count >= 5) break;
      }
      if (count === 0) {
        return {
          ok: false,
          productsDetected: 0,
          sample: [],
          error: {
            code: ERROR_CODES.MALFORMED_PRODUCT,
            userMessage: "Connected to the feed, but no products could be read from it.",
            technical: "feed yielded 0 rows",
          },
        };
      }
      return { ok: true, productsDetected: null, sample };
    } catch (err) {
      return { ok: false, productsDetected: null, sample: [], error: toSafeError(err) };
    }
  }

  async *fetchProductPages(opts = {}) {
    const stream = await openFeedStream(this.store.feedUrl, {
      headers: this._authHeaders(),
      timeoutMs: this.timeoutMs,
    });

    if (this.format === FEED_FORMATS.CSV) {
      yield* this._pageCsv(stream, opts);
    } else if (this.format === FEED_FORMATS.XML) {
      yield* this._pageXml(stream, opts);
    } else if (this.format === FEED_FORMATS.JSON) {
      yield* this._pageJson(stream, opts);
    } else {
      throw new SyncError(ERROR_CODES.INVALID_CONFIG, `unsupported feedFormat "${this.format}"`);
    }
  }

  async *_pageCsv(stream, opts) {
    let parseFn;
    try {
      ({ parse: parseFn } = await import("csv-parse"));
    } catch {
      throw new SyncError(
        ERROR_CODES.INVALID_CONFIG,
        "csv-parse is not installed; run `npm install` in scripts/affiliate-sync",
      );
    }
    const parser = stream.pipe(
      parseFn({
        columns: true,
        bom: true,
        skip_empty_lines: true,
        relax_quotes: true,
        relax_column_count: true,
        trim: true,
      }),
    );
    let page = [];
    let total = 0;
    for await (const record of parser) {
      page.push(this.normalizeProduct(record));
      total += 1;
      if (page.length >= this.pageSize) {
        yield page;
        page = [];
      }
      if (opts.sampleLimit && total >= opts.sampleLimit) break;
    }
    if (page.length) yield page;
  }

  async *_pageXml(stream, opts) {
    let XMLParser;
    try {
      ({ XMLParser } = await import("fast-xml-parser"));
    } catch {
      throw new SyncError(
        ERROR_CODES.INVALID_CONFIG,
        "fast-xml-parser is not installed; run `npm install` in scripts/affiliate-sync",
      );
    }
    const chunks = [];
    for await (const c of stream) chunks.push(c);
    const xml = Buffer.concat(chunks).toString("utf8");
    const parsed = new XMLParser({ ignoreAttributes: false, trimValues: true }).parse(xml);
    const items = this._itemsFromTree(parsed);
    yield* this._pageArray(items, opts);
  }

  async *_pageJson(stream, opts) {
    const chunks = [];
    for await (const c of stream) chunks.push(c);
    let parsed;
    try {
      parsed = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    } catch (err) {
      throw new SyncError(ERROR_CODES.MALFORMED_PRODUCT, `feed is not valid JSON: ${err.message}`);
    }
    const items = Array.isArray(parsed) ? parsed : this._itemsFromTree(parsed);
    yield* this._pageArray(items, opts);
  }

  _itemsFromTree(tree) {
    const path = this.store.feedItemPath;
    if (path) {
      const node = path.split(".").reduce((acc, k) => (acc == null ? acc : acc[k]), tree);
      if (Array.isArray(node)) return node;
      if (node && typeof node === "object") return [node];
      return [];
    }
    // Heuristic: first array of objects found anywhere in the tree.
    const stack = [tree];
    while (stack.length) {
      const cur = stack.shift();
      if (Array.isArray(cur) && cur.length && typeof cur[0] === "object") return cur;
      if (cur && typeof cur === "object") stack.push(...Object.values(cur));
    }
    return [];
  }

  async *_pageArray(items, opts) {
    let page = [];
    let total = 0;
    for (const record of items) {
      page.push(this.normalizeProduct(record));
      total += 1;
      if (page.length >= this.pageSize) {
        yield page;
        page = [];
      }
      if (opts.sampleLimit && total >= opts.sampleLimit) break;
    }
    if (page.length) yield page;
  }
}
