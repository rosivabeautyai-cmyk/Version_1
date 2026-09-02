/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * MockConnector — a fully working connector that needs no third-party
 * credentials. It lets the ENTIRE pipeline (Test Connection, Sync Now,
 * scheduled sync, upsert, deactivation, logs, Admin UI, security rules)
 * be exercised end-to-end in development and CI.
 *
 * Replace it with a real connector by:
 *   1. setting the store's integrationType to product_feed / rest_api /
 *      affiliate_network, and
 *   2. filling in the matching config on the affiliateStores document.
 *
 * The dataset is deterministic and seeded from the store id so repeated
 * syncs are idempotent, and a second run with `variant: 'drift'` proves
 * upsert + deactivation behaviour.
 */

import { ProductConnector } from "./ProductConnector.mjs";
import { toSafeError } from "../lib/errors.mjs";

const SKUS = [
  { sku: "SERUM-001", name: "Hydra Boost Vitamin C Serum", brand: "Lumea", cat: "Serums", price: 29.99, rrp: 39.99 },
  { sku: "CREAM-002", name: "Night Repair Moisturizer", brand: "Lumea", cat: "Moisturizers", price: 42.0, rrp: 42.0 },
  { sku: "FND-003", name: "Second Skin Foundation SPF20", brand: "Velvet", cat: "Foundation", price: 33.5, rrp: 38.0 },
  { sku: "LIP-004", name: "Matte Ink Lipstick — Rosewood", brand: "Velvet", cat: "Lipstick", price: 18.0, rrp: 18.0 },
  { sku: "EDP-005", name: "Amber Oud Eau de Parfum 50ml", brand: "Maison N", cat: "Fragrance", price: 74.0, rrp: 89.0 },
  { sku: "CLNZ-006", name: "Gentle Gel Cleanser", brand: "Lumea", cat: "Face Care", price: 21.0, rrp: 21.0 },
  { sku: "MASC-007", name: "Volume Lash Mascara", brand: "Velvet", cat: "Mascara", price: 22.5, rrp: 25.0 },
  { sku: "PERF-008", name: "Rose Petal Perfume 30ml", brand: "Maison N", cat: "Perfume", price: 55.0, rrp: 55.0 },
];

export class MockConnector extends ProductConnector {
  /**
   * @param {object} store
   * @param {object} [secrets]
   * @param {object} [opts]
   * @param {'stable'|'drift'} [opts.variant]  'drift' drops 2 SKUs + bumps prices
   * @param {number} [opts.pageSize]
   */
  constructor(store, secrets = {}, opts = {}) {
    super(store, secrets);
    this.variant = opts.variant || store?.mock?.variant || "stable";
    this.pageSize = opts.pageSize || 3;
  }

  _dataset() {
    let rows = SKUS.slice();
    if (this.variant === "drift") {
      rows = rows.slice(0, rows.length - 2).map((r) => ({ ...r, price: Math.round((r.price + 1) * 100) / 100 }));
    }
    return rows;
  }

  _toRecord(row) {
    const slug = this.store.slug || this.store.id;
    return {
      externalProductId: row.sku,
      name: row.name,
      description: `${row.name} by ${row.brand}. Imported via ROSIVA mock connector for store "${slug}".`,
      brand: row.brand,
      categoryName: row.cat,
      price: row.price,
      oldPrice: row.rrp,
      currency: this.store.currency || "USD",
      imageUrl: `https://picsum.photos/seed/${encodeURIComponent(slug + "-" + row.sku)}/600/600`,
      additionalImages: [],
      productUrl: `https://example-store.test/${slug}/p/${row.sku}`,
      // A realistic-looking deep link WITHOUT inventing a real network's
      // tracking params — this is clearly a mock host.
      deepLink: `https://go.example-affiliate.test/click?store=${encodeURIComponent(slug)}&url=${encodeURIComponent(
        `https://example-store.test/${slug}/p/${row.sku}`,
      )}`,
      availability: "in stock",
      rating: 4.2,
      reviewCount: 128,
      updatedAt: new Date().toISOString(),
    };
  }

  async testConnection() {
    try {
      const rows = this._dataset();
      return {
        ok: true,
        productsDetected: rows.length,
        sample: rows.slice(0, 5).map((r) => this._toRecord(r)),
      };
    } catch (err) {
      return { ok: false, productsDetected: null, sample: [], error: toSafeError(err) };
    }
  }

  async *fetchProductPages() {
    const rows = this._dataset();
    for (let i = 0; i < rows.length; i += this.pageSize) {
      yield rows.slice(i, i + this.pageSize).map((r) => this._toRecord(r));
    }
  }

  normalizeProduct(record) {
    return {
      externalProductId: record.externalProductId,
      name: record.name,
      description: record.description,
      brand: record.brand,
      categoryName: record.categoryName,
      price: record.price,
      oldPrice: record.oldPrice,
      currency: record.currency,
      imageUrl: record.imageUrl,
      additionalImages: record.additionalImages,
      productUrl: record.productUrl,
      affiliateUrl: this.buildAffiliateUrl(record),
      availability: record.availability,
      rating: record.rating,
      reviewCount: record.reviewCount,
      updatedAt: record.updatedAt,
    };
  }
}
