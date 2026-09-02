/**
 * Product Normalizer.
 *
 *   External source -> Connector -> RAW product -> [ Normalizer ] -> ROSIVA product -> Firestore
 *
 * A "raw product" is whatever a connector's `normalizeProduct()` chose
 * to emit — a loose, source-shaped object. This module turns it into
 * the single ROSIVA product document shape the Flutter app already
 * reads (see lib/Feature/products/data/models/product_model.dart) and
 * enforces the invariants the rest of the system relies on:
 *
 *   - document id / `externalProductId` uniqueness (storeId + externalProductId)
 *   - required fields (id, name, product URL)
 *   - category resolved to one of ROSIVA's 3 canonical slugs
 *   - commission metadata by priority
 *   - affiliate URL preferred for "Shop Now"
 */

import { AVAILABILITY, PRODUCT_SOURCE } from "./constants.mjs";
import { SyncError, ERROR_CODES } from "./errors.mjs";
import { resolveCommission } from "./commission.mjs";

/**
 * Deterministic Firestore document id for an imported product.
 * NEVER derived from the product name — different stores can sell a
 * product with the same name.
 *
 * @param {string} storeId
 * @param {string} externalProductId
 * @return {string}
 */
export function buildProductDocId(storeId, externalProductId) {
  const s = String(storeId || "").trim();
  const e = String(externalProductId || "").trim();
  if (!s) throw new SyncError(ERROR_CODES.INVALID_CONFIG, "storeId is required for a product doc id");
  if (!e) throw new SyncError(ERROR_CODES.MISSING_PRODUCT_ID, "externalProductId is required");
  // Firestore doc ids cannot contain '/'. Everything else is fine; we
  // keep it readable ("store_123:SHEIN_987654").
  return `${sanitizeIdPart(s)}:${sanitizeIdPart(e)}`;
}

function sanitizeIdPart(v) {
  return String(v).replace(/\//g, "_").slice(0, 400);
}

function toNumberOrNull(v) {
  if (v == null || v === "") return null;
  const n = typeof v === "number" ? v : parseFloat(String(v).replace(/[^0-9.\-]/g, ""));
  return Number.isFinite(n) ? n : null;
}

function toStringOrNull(v) {
  if (v == null) return null;
  const s = String(v).trim();
  return s.length ? s : null;
}

function toStringList(v) {
  if (Array.isArray(v)) return v.map((x) => String(x).trim()).filter(Boolean);
  if (typeof v === "string") {
    return v
      .split(/[|,;]/)
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return [];
}

function normalizeAvailability(raw) {
  if (raw === true) return AVAILABILITY.IN_STOCK;
  if (raw === false) return AVAILABILITY.OUT_OF_STOCK;
  const s = String(raw ?? "").trim().toLowerCase();
  if (!s) return AVAILABILITY.UNKNOWN;
  if (["1", "true", "yes", "in stock", "in_stock", "instock", "available"].includes(s)) {
    return AVAILABILITY.IN_STOCK;
  }
  if (
    ["0", "false", "no", "out of stock", "out_of_stock", "oos", "unavailable", "sold out"].includes(s)
  ) {
    return AVAILABILITY.OUT_OF_STOCK;
  }
  return AVAILABILITY.UNKNOWN;
}

/**
 * @param {object} args
 * @param {object} args.raw           the connector's raw product
 * @param {object} args.store         the affiliateStores document (must carry `id`)
 * @param {(source:string, storeId?:string)=>(string|null)} args.resolveCategory
 * @param {string} [args.nowIso]      injected clock for tests
 * @return {{ ok: true, docId: string, doc: object } | { ok: false, code: string, technical: string }}
 */
export function normalizeProduct({ raw, store, resolveCategory, nowIso } = {}) {
  const now = nowIso || new Date().toISOString();

  if (!raw || typeof raw !== "object") {
    return { ok: false, code: ERROR_CODES.MALFORMED_PRODUCT, technical: "raw product is not an object" };
  }
  if (!store || !store.id) {
    return { ok: false, code: ERROR_CODES.INVALID_CONFIG, technical: "store.id missing" };
  }

  const externalProductId = toStringOrNull(raw.externalProductId ?? raw.externalId ?? raw.id);
  if (!externalProductId) {
    return { ok: false, code: ERROR_CODES.MISSING_PRODUCT_ID, technical: "no externalProductId" };
  }

  const name = toStringOrNull(raw.name);
  if (!name) {
    return {
      ok: false,
      code: ERROR_CODES.MISSING_PRODUCT_NAME,
      technical: `product ${externalProductId} has no name`,
    };
  }

  const productUrl = toStringOrNull(raw.productUrl ?? raw.url);
  const affiliateUrl = toStringOrNull(raw.affiliateUrl ?? raw.deepLink ?? raw.aw_deep_link);
  if (!productUrl && !affiliateUrl) {
    return {
      ok: false,
      code: ERROR_CODES.MISSING_PRODUCT_URL,
      technical: `product ${externalProductId} has neither productUrl nor affiliateUrl`,
    };
  }

  const price = toNumberOrNull(raw.price);
  if (raw.price != null && raw.price !== "" && price == null) {
    return {
      ok: false,
      code: ERROR_CODES.INVALID_PRICE,
      technical: `product ${externalProductId} price "${raw.price}" is not a number`,
    };
  }
  if (price != null && price < 0) {
    return {
      ok: false,
      code: ERROR_CODES.INVALID_PRICE,
      technical: `product ${externalProductId} price ${price} is negative`,
    };
  }

  // A connector that has ALREADY done proper ROSIVA women's-beauty
  // classification (currently only the Awin connector, using the same
  // classifier the legacy sync uses) passes the verdict through here.
  // Everything else stays `isRosivaProduct: false` (excluded from the
  // AI catalog) and relies purely on category resolution.
  const passthrough =
    raw.rosivaClassification && typeof raw.rosivaClassification === "object"
      ? raw.rosivaClassification
      : null;

  const rosivaCategory = passthrough?.rosivaCategory
    ? passthrough.rosivaCategory
    : resolveCategory
      ? resolveCategory(raw.categoryName ?? raw.category ?? raw.merchantCategory, store.id)
      : null;

  const oldPrice = toNumberOrNull(raw.oldPrice ?? raw.rrpPrice ?? raw.rrp_price);
  const salePrice = toNumberOrNull(raw.salePrice);
  let discountPercentage = toNumberOrNull(raw.discountPercentage);
  if (discountPercentage == null && oldPrice && price && oldPrice > price) {
    discountPercentage = Math.round(((oldPrice - price) / oldPrice) * 100);
  }

  const commission = resolveCommission({
    productCommissionRate: raw.commissionRate,
    store,
  });

  const availability = normalizeAvailability(raw.availability ?? raw.inStock ?? raw.in_stock);
  const inStock = availability !== AVAILABILITY.OUT_OF_STOCK;

  const docId = buildProductDocId(store.id, externalProductId);

  const imageUrl = toStringOrNull(raw.imageUrl ?? raw.image);
  const images = toStringList(raw.additionalImages ?? raw.images);

  // The document shape below is a SUPERSET of what ProductModel.fromJson
  // already reads. New keys (storeId, externalProductId, availability,
  // productUrl, affiliateUrl, commissionRate, source, isActive,
  // lastSyncedAt) are additive and ignored by older readers.
  const doc = {
    id: docId,
    storeId: store.id,
    externalProductId,
    source: PRODUCT_SOURCE.AFFILIATE,

    name,
    description: toStringOrNull(raw.description),
    brand: toStringOrNull(raw.brand),

    // Legacy `category` mirrors `rosivaCategory` for the existing query
    // layer; `rosivaCategory` is authoritative.
    category: rosivaCategory,
    rosivaCategory,
    categoryName: toStringOrNull(raw.categoryName ?? raw.category),
    // Imported affiliate products are NOT run through the women's-beauty
    // classifier, so they are excluded from the AI catalog by default —
    // exactly like admin-authored products. A rosivaCategory match still
    // lets them show in the category screens via the shopper query.
    isRosivaProduct: passthrough ? passthrough.isRosivaProduct === true : false,
    gender: passthrough?.gender || toStringOrNull(raw.gender) || "unknown",
    classificationReason: passthrough?.classificationReason ?? null,

    price,
    oldPrice,
    salePrice,
    currency: (toStringOrNull(raw.currency) || store.currency || "USD").toUpperCase(),
    discountPercentage: discountPercentage ?? 0,

    imageUrl,
    images,

    productUrl: productUrl || affiliateUrl,
    affiliateUrl: affiliateUrl || productUrl,
    // Keep `storeUrl` populated with the affiliate/deep link so the
    // existing "Shop Now" path (product.offerFor().storeUrl) keeps
    // working with zero UI change.
    storeUrl: affiliateUrl || productUrl,

    availability,
    inStock,

    rating: toNumberOrNull(raw.rating),
    reviewCount: toNumberOrNull(raw.reviewCount) ?? null,

    commissionRate: commission.rate,
    commissionType: commission.type,
    commissionSource: commission.source,

    tags: toStringList(raw.tags),
    ingredients: toStringList(raw.ingredients),

    isActive: raw.isActive === false ? false : true,
    isFeatured: raw.isFeatured === true,
    featured: raw.isFeatured === true,
    active: raw.isActive === false ? false : true,

    externalUpdatedAt: toStringOrNull(raw.updatedAt ?? raw.lastUpdated),
    lastSyncedAt: now,
    syncedAt: now,
    updatedAt: now,
  };

  return { ok: true, docId, doc };
}
