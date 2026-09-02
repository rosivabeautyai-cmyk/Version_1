/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * AwinProductFeedConnector — the real Awin integration, refactored from
 * the proven scripts/awin-sync/awinSync.mjs field mapping. Awin (as an
 * affiliate NETWORK) delivers product data as a downloadable CSV feed
 * (optionally gzipped) that already contains the publisher deep link
 * (`aw_deep_link`). No scraping, no undocumented API.
 *
 * The private part of an Awin feed URL is the publisher id + API token
 * embedded in the path. That whole URL is a SECRET: it is supplied to
 * the backend via the `AWIN_FEED_URL` (or `AFFILIATE_<SLUG>_FEED_URL`)
 * environment variable and is never stored on the affiliateStores
 * document or sent to Flutter. The store document only records that the
 * integration is Awin.
 *
 * Optionally runs ROSIVA's women's-beauty classifier (the same one the
 * legacy sync uses) so a fully-migrated Awin store produces documents
 * equivalent to the ones scripts/awin-sync writes today.
 */

import { ProductFeedConnector } from "./ProductFeedConnector.mjs";
import { SyncError, ERROR_CODES } from "../lib/errors.mjs";

const AWIN_FIELD_MAP = {
  externalProductId: "aw_product_id",
  name: "product_name",
  description: "description",
  brand: "brand_name",
  categoryName: "category_name",
  currency: "currency",
  productUrl: "merchant_deep_link",
  affiliateUrl: "aw_deep_link",
  availability: "in_stock",
  rating: "average_rating",
  reviewCount: "reviews",
  oldPrice: "rrp_price",
};

export class AwinProductFeedConnector extends ProductFeedConnector {
  constructor(store, secrets = {}, opts = {}) {
    // The Awin feed URL is a secret: prefer the one resolved from the
    // backend environment; fall back to any public non-secret feedUrl
    // (e.g. a mock URL used in tests).
    const feedUrl = secrets.AWIN_FEED_URL || secrets.FEED_URL || store.feedUrl || "";
    super({ ...store, feedUrl, feedFormat: "csv", fieldMap: AWIN_FIELD_MAP }, secrets, opts);
    // Default ON — matches legacy behaviour. Set store.awinClassify === false to skip.
    this.classify = store.awinClassify !== false;
    this._classifyFn = opts._classifyFn || null;
  }

  async _loadClassifier() {
    if (this._classifyFn) return this._classifyFn;
    try {
      const mod = await import("../../awin-sync/rosivaClassifier.mjs");
      this._classifyFn = mod.classifyProduct;
    } catch (err) {
      throw new SyncError(
        ERROR_CODES.INVALID_CONFIG,
        `Awin classifier unavailable: ${err.message}`,
      );
    }
    return this._classifyFn;
  }

  _parsePrice(record) {
    for (const field of ["search_price", "display_price", "store_price"]) {
      const rawv = record[field];
      if (!rawv) continue;
      const num = parseFloat(String(rawv).replace(/[^0-9.\-]/g, ""));
      if (Number.isFinite(num) && num > 0) return num;
    }
    return null;
  }

  normalizeProduct(record) {
    const raw = super.normalizeProduct(record);
    raw.price = this._parsePrice(record);
    raw.imageUrl =
      record.large_image || record.merchant_image_url || record.aw_image_url || null;
    raw.additionalImages = [
      record.alternate_image,
      record.alternate_image_two,
      record.alternate_image_three,
    ].filter((v) => !!v && String(v).trim().length > 0);
    raw.affiliateUrl = record.aw_deep_link?.trim() || raw.affiliateUrl || null;
    raw.productUrl = record.merchant_deep_link?.trim() || raw.affiliateUrl;
    raw.tags = record.keywords || "";
    // Carry the raw merchant category signals for classification.
    raw._awinCategorySignals = [
      record.category_name,
      record.merchant_category,
      record.merchant_product_category_path,
    ]
      .filter(Boolean)
      .join(" ");
    return raw;
  }

  /**
   * Post-process a page through the classifier (when enabled). Products
   * the classifier rejects are dropped (returned as null) exactly like
   * the legacy sync — a floor cleaner in a general retail feed has
   * nothing useful to become.
   */
  async _classifyPage(page) {
    if (!this.classify) return page;
    const classifyProduct = await this._loadClassifier();
    const out = [];
    for (const raw of page) {
      const c = classifyProduct({
        name: raw.name,
        merchantCategory: raw._awinCategorySignals || raw.categoryName,
        description: raw.description,
        brand: raw.brand,
        tags: raw.tags,
      });
      if (!c.isRosivaProduct) continue;
      raw.rosivaClassification = {
        isRosivaProduct: c.isRosivaProduct,
        rosivaCategory: c.rosivaCategory,
        gender: c.gender,
        classificationReason: c.classificationReason,
      };
      raw.categoryName = raw.categoryName || c.rosivaCategory;
      delete raw._awinCategorySignals;
      out.push(raw);
    }
    return out;
  }

  async *fetchProductPages(opts = {}) {
    for await (const page of super.fetchProductPages(opts)) {
      const processed = await this._classifyPage(page);
      if (processed.length) yield processed;
    }
  }
}
