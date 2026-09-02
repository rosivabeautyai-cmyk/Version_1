/**
 * Awin product feed -> Firestore `products` collection.
 *
 * Standalone script (run by GitHub Actions, not Firebase Cloud
 * Functions) so the sync doesn't require the Firebase Blaze plan or
 * Firebase Functions secrets. Downloads the configured Awin feed
 * (CSV, optionally gzipped), streams + parses it without loading the
 * whole file into memory, filters rows down to Skincare/Makeup/Perfume
 * (see rosivaClassifier.mjs), maps each row onto the same
 * ProductModel-compatible document shape the app already expects, and
 * upserts into `products/{aw_product_id}` via BulkWriter so repeated
 * syncs update rather than duplicate.
 *
 * Ported from the original functions/src/awinSync.ts — the parsing,
 * filtering, and field-mapping logic is unchanged; only how the
 * script authenticates to Firebase and how it's invoked/scheduled
 * changed (env vars + GitHub Actions instead of Firebase Functions
 * secrets + Cloud Scheduler).
 *
 * Required environment variables:
 *   AWIN_FEED_URL               The Awin feed download URL.
 *   FIREBASE_SERVICE_ACCOUNT_JSON  A Firebase/GCP service account key
 *                                  (full JSON, as a string) with
 *                                  Firestore read/write access.
 */

import {Readable} from "node:stream";
import * as zlib from "node:zlib";

import {parse} from "csv-parse";
import {cert, getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import {classifyProduct} from "./rosivaClassifier.mjs";

const PRODUCTS_COLLECTION = "products";
const CATEGORIES_COLLECTION = "categories";
const SYNC_STATUS_DOC = "admin/awinSyncStatus";

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set."
    );
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. Make sure the " +
        "full service account key file contents were pasted as-is."
    );
  }
}

function initFirebase() {
  if (getApps().length === 0) {
    initializeApp({credential: cert(loadServiceAccount())});
  }
  return getFirestore();
}

/**
 * Picks the first valid, positive numeric price from Awin's price
 * fields, in order of reliability.
 */
function parsePrice(row) {
  for (const field of ["search_price", "display_price", "store_price"]) {
    const raw = row[field];
    if (!raw) continue;
    const num = parseFloat(String(raw).replace(/[^0-9.-]/g, ""));
    if (Number.isFinite(num) && num > 0) return num;
  }
  return null;
}

/** Parses an optional numeric field, tolerating blank/invalid input. */
function parseOptionalNumber(raw) {
  if (!raw) return null;
  const num = parseFloat(raw);
  return Number.isFinite(num) ? num : null;
}

/** Parses an optional integer field, tolerating blank/invalid input. */
function parseOptionalInt(raw) {
  if (!raw) return null;
  const num = parseInt(raw, 10);
  return Number.isFinite(num) ? num : null;
}

/** Interprets Awin's `in_stock` field as a boolean. */
function toBool(raw) {
  if (!raw) return false;
  const v = raw.trim().toLowerCase();
  return v === "true" || v === "1" || v === "yes" || v === "in stock";
}

/** Splits a delimited Awin list field (e.g. keywords) into an array. */
function splitList(raw) {
  if (!raw) return [];
  return raw
    .split(/[|,;]/)
    .map((s) => s.trim())
    .filter(Boolean);
}

/**
 * Opens the feed URL as a Node stream, transparently decompressing
 * gzip based on the actual file magic bytes (0x1f 0x8b) rather than
 * trusting headers/URL naming, since Awin feed delivery doesn't
 * always advertise this consistently.
 */
async function openFeedStream(feedUrl) {
  const response = await fetch(feedUrl);
  if (!response.ok || !response.body) {
    throw new Error(`Failed to download Awin feed: HTTP ${response.status}`);
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
    })()
  );

  return isGzip ? combined.pipe(zlib.createGunzip()) : combined;
}

/**
 * Downloads, parses, filters, maps, and upserts the Awin feed into
 * Firestore, recording progress/result in `admin/awinSyncStatus`.
 */
async function runAwinSync(feedUrl) {
  const db = initFirebase();
  const statusRef = db.doc(SYNC_STATUS_DOC);
  await statusRef.set(
    {status: "running", startedAt: new Date().toISOString()},
    {merge: true}
  );

  let processed = 0;
  let imported = 0;
  let skipped = 0;
  const categoryCounts = {skincare: 0, makeup: 0, perfume: 0};

  try {
    const stream = await openFeedStream(feedUrl);
    const parser = stream.pipe(
      parse({
        columns: true,
        bom: true,
        skip_empty_lines: true,
        relax_quotes: true,
        relax_column_count: true,
        trim: true,
      })
    );

    const bulkWriter = db.bulkWriter();
    bulkWriter.onWriteError((error) => error.failedAttempts < 3);

    for await (const record of parser) {
      processed++;

      const productId = record.aw_product_id?.trim();
      if (!productId) {
        skipped++;
        continue;
      }

      // The Awin feed is a general retailer feed (household
      // cleaning, electronics, clothing, etc. alongside real beauty
      // products) — classifyProduct() is ROSIVA's eligibility filter,
      // not just a category label. Products that fail it (denied, or
      // matched no beauty category at all) are never written to
      // Firestore — there's nothing useful to do with a floor cleaner
      // regardless of gender/visibility flags. Products that pass are
      // ALWAYS written with isRosivaProduct: true — gender never
      // affects eligibility, only whether the app's default catalog
      // query later shows it (see ProductApiService).
      const classification = classifyProduct({
        name: record.product_name,
        // Joined rather than `||`-picking one — every one of these
        // Awin category-ish fields is a real signal and none should
        // be discarded just because an earlier one was non-empty.
        merchantCategory: [
          record.category_name,
          record.merchant_category,
          record.merchant_product_category_path,
        ]
          .filter(Boolean)
          .join(" "),
        description: record.description,
        brand: record.brand_name,
        tags: record.keywords,
      });
      if (!classification.isRosivaProduct) {
        skipped++;
        continue;
      }
      const category = classification.rosivaCategory;

      const imageUrl =
        record.large_image ||
        record.merchant_image_url ||
        record.aw_image_url ||
        null;
      const images = [
        record.alternate_image,
        record.alternate_image_two,
        record.alternate_image_three,
      ].filter((v) => !!v && v.trim().length > 0);

      const currencyRaw = record.currency?.trim();

      const doc = {
        id: productId,
        name: record.product_name?.trim() || "",
        brand: record.brand_name?.trim() || null,
        description: record.description?.trim() || null,
        price: parsePrice(record),
        currency: currencyRaw || "USD",
        // True only when the feed row carried no currency and we had to
        // default. The app suppresses the approximate converted price
        // for these — a wrong number is worse than none.
        currencyAssumed: !currencyRaw,
        imageUrl,
        images,
        rating: parseOptionalNumber(record.average_rating),
        reviewCount: parseOptionalInt(record.reviews),
        category,
        // ROSIVA eligibility fields — separate from `category` /
        // `merchantCategory` (Awin's own, untouched taxonomy, kept
        // below) on purpose: `category` already mirrors
        // `rosivaCategory` for backward compatibility with the
        // existing app query layer, but eligibility itself is
        // decided by `isRosivaProduct`, not by category presence.
        rosivaCategory: classification.rosivaCategory,
        isRosivaProduct: classification.isRosivaProduct,
        gender: classification.gender,
        classificationReason: classification.classificationReason,
        tags: splitList(record.keywords),
        ingredients: [],
        benefits: "",
        howToUse: "",
        whyRecommended: "",
        isEditorsChoice: false,
        storeUrl: record.aw_deep_link?.trim() || null,
        inStock: toBool(record.in_stock),

        // Awin metadata — not read by the Flutter ProductModel today,
        // kept for admin visibility / future use.
        awProductId: productId,
        merchantProductId: record.merchant_product_id || null,
        merchantId: record.merchant_id || null,
        merchantName: record.merchant_name || null,
        merchantCategory: record.merchant_category || null,
        dataFeedId: record.data_feed_id || null,
        ean: record.ean || null,
        mpn: record.mpn || null,
        productGTIN: record.product_GTIN || null,
        lastUpdated: record.last_updated || null,
        saving: parseOptionalNumber(record.saving),
        savingsPercent: parseOptionalNumber(record.savings_percent),
        rrpPrice: parseOptionalNumber(record.rrp_price),
        deliveryCost: parseOptionalNumber(record.delivery_cost),
        syncedAt: new Date().toISOString(),
      };

      bulkWriter.set(
        db.collection(PRODUCTS_COLLECTION).doc(productId),
        doc,
        {merge: true}
      );
      imported++;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    await bulkWriter.close();

    const categoryBatch = db.batch();
    for (const [slug, count] of Object.entries(categoryCounts)) {
      categoryBatch.set(
        db.collection(CATEGORIES_COLLECTION).doc(slug),
        {
          id: slug,
          slug,
          name: slug.charAt(0).toUpperCase() + slug.slice(1),
          productCount: count,
        },
        {merge: true}
      );
    }
    await categoryBatch.commit();

    await statusRef.set(
      {
        status: "success",
        finishedAt: new Date().toISOString(),
        processed,
        imported,
        skipped,
        categoryCounts,
      },
      {merge: true}
    );

    console.log("Awin sync finished", {processed, imported, skipped, categoryCounts});
    return {processed, imported, skipped, categoryCounts};
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await statusRef.set(
      {
        status: "error",
        finishedAt: new Date().toISOString(),
        error: message,
        processed,
        imported,
        skipped,
      },
      {merge: true}
    );
    console.error("Awin sync failed", message);
    throw error;
  }
}

const feedUrl = process.env.AWIN_FEED_URL;
if (!feedUrl) {
  console.error("AWIN_FEED_URL environment variable is not set.");
  process.exit(1);
}

try {
  const result = await runAwinSync(feedUrl);
  console.log("Done:", result);
  process.exit(0);
} catch (error) {
  console.error(error);
  process.exit(1);
}
