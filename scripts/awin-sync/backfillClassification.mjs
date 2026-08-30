/**
 * Backfills `isRosivaProduct` / `rosivaCategory` / `gender` /
 * `classificationReason` onto EXISTING `products` documents that
 * were imported before this classification system existed.
 *
 * Never deletes anything. By default runs as a DRY RUN — it reads
 * every product, re-classifies it with the exact same
 * rosivaClassifier.mjs the live sync uses, and prints a report
 * (counts allowed/excluded, by category, by gender, and example
 * excluded products) WITHOUT writing anything to Firestore.
 *
 * Only writes when you explicitly pass --apply, and even then only
 * ever does additive `{merge: true}` field updates — it never removes
 * or overwrites `category`, `merchantCategory`, `merchantName`,
 * `merchantId`, `dataFeedId`, `awProductId`, `merchantProductId`, or
 * any other existing field.
 *
 * Idempotent: re-running (dry-run or --apply) on the same product
 * data always produces the same classification, since it's the same
 * pure function the sync uses.
 *
 * Usage (from scripts/awin-sync/):
 *   # Report only — the default, and the safe first step:
 *   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)" node backfillClassification.mjs
 *
 *   # Actually write the classification fields (still never deletes):
 *   FIREBASE_SERVICE_ACCOUNT_JSON="$(cat /path/to/service-account.json)" node backfillClassification.mjs --apply
 */

import {cert, getApps, initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";

import {ROSIVA_CATEGORIES, classifyProduct} from "./rosivaClassifier.mjs";

const PRODUCTS_COLLECTION = "products";
const CATEGORIES_COLLECTION = "categories";

function loadServiceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set."
    );
  }
  return JSON.parse(raw);
}

function initFirebase() {
  if (getApps().length === 0) {
    initializeApp({credential: cert(loadServiceAccount())});
  }
  return getFirestore();
}

async function main() {
  const apply = process.argv.includes("--apply");
  const db = initFirebase();

  const snapshot = await db.collection(PRODUCTS_COLLECTION).get();
  console.log(`Read ${snapshot.size} existing products.\n`);

  let allowed = 0;
  let excluded = 0;
  const byCategory = {skincare: 0, makeup: 0, perfume: 0};
  const byGender = {women: 0, men: 0, unisex: 0, unknown: 0};
  const excludedExamples = [];
  const eligibleExamples = {skincare: [], makeup: [], perfume: []};
  const exclusionReasonCounts = new Map();
  const changedCategory = [];
  const invariantViolations = [];

  /** Buckets a raw classificationReason into a stable, countable label. */
  function reasonBucket(classification) {
    if (classification.isRosivaProduct) return null;
    const r = classification.classificationReason;
    if (r.startsWith("denied:")) return `Denied — ${r.slice("denied: matched ".length)}`;
    if (r.includes("gender=")) {
      const category = classification.rosivaCategory ?? "?";
      return `Real ${category} product, but gender=${classification.gender} (women-only catalog)`;
    }
    return "No category keyword matched (not skincare/makeup/perfume)";
  }

  const bulkWriter = apply ? db.bulkWriter() : null;
  if (bulkWriter) bulkWriter.onWriteError((error) => error.failedAttempts < 3);

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const classification = classifyProduct({
      name: data.name,
      merchantCategory: [data.merchantCategory, data.category]
        .filter(Boolean)
        .join(" "),
      description: data.description,
      brand: data.brand,
      tags: Array.isArray(data.tags) ? data.tags.join(" ") : undefined,
    });

    if (classification.isRosivaProduct) {
      // Invariant check (requirement #7): every eligible product must
      // satisfy Women + a real ROSIVA category — this should be
      // structurally guaranteed by classifyProduct() itself, but
      // verifying it here at runtime catches any future regression
      // rather than silently trusting it.
      if (
        classification.gender !== "women" ||
        !ROSIVA_CATEGORIES.includes(classification.rosivaCategory)
      ) {
        invariantViolations.push({id: doc.id, name: data.name, classification});
      }

      allowed++;
      byCategory[classification.rosivaCategory] =
        (byCategory[classification.rosivaCategory] ?? 0) + 1;
      const examples = eligibleExamples[classification.rosivaCategory];
      if (examples.length < 5) {
        examples.push({id: doc.id, name: data.name, brand: data.brand});
      }
    } else {
      excluded++;
      if (excludedExamples.length < 20) {
        excludedExamples.push({
          id: doc.id,
          name: data.name,
          merchantCategory: data.merchantCategory,
          reason: classification.classificationReason,
        });
      }
      const bucket = reasonBucket(classification);
      exclusionReasonCounts.set(bucket, (exclusionReasonCounts.get(bucket) ?? 0) + 1);
    }
    byGender[classification.gender] = (byGender[classification.gender] ?? 0) + 1;

    // Existing product already had a `category` from the old,
    // narrower classifier — flag (not silently apply) any case where
    // re-classifying changes it, since that's the most important
    // thing to sanity-check before trusting --apply.
    if (
      data.category &&
      classification.rosivaCategory &&
      data.category !== classification.rosivaCategory
    ) {
      changedCategory.push({
        id: doc.id,
        name: data.name,
        was: data.category,
        now: classification.rosivaCategory,
      });
    }

    if (apply) {
      bulkWriter.set(
        db.collection(PRODUCTS_COLLECTION).doc(doc.id),
        {
          isRosivaProduct: classification.isRosivaProduct,
          rosivaCategory: classification.rosivaCategory,
          gender: classification.gender,
          classificationReason: classification.classificationReason,
        },
        {merge: true}
      );
    }
  }

  if (apply) {
    await bulkWriter.close();

    // Keep `categories/{slug}.productCount` honest — only counts
    // products that are both classified into that category AND
    // eligible (excluded products were never counted here anyway
    // since the loop above only increments byCategory for eligible
    // ones).
    const categoryBatch = db.batch();
    for (const [slug, count] of Object.entries(byCategory)) {
      categoryBatch.set(
        db.collection(CATEGORIES_COLLECTION).doc(slug),
        {productCount: count},
        {merge: true}
      );
    }
    await categoryBatch.commit();
  }

  console.log(`=== ${apply ? "APPLIED" : "DRY RUN (no writes)"} ===\n`);

  console.log(`Total products:              ${snapshot.size}`);
  console.log(`Eligible ROSIVA products:    ${allowed}`);
  console.log(`Excluded products:           ${excluded}\n`);

  console.log(`Skincare: ${byCategory.skincare}`);
  console.log(`Makeup:   ${byCategory.makeup}`);
  console.log(`Perfume:  ${byCategory.perfume}\n`);

  console.log(`Women:    ${byGender.women}`);
  console.log(`Men:      ${byGender.men}`);
  console.log(`Unisex:   ${byGender.unisex}`);
  console.log(`Unknown:  ${byGender.unknown}\n`);

  console.log("Exclusion reasons (grouped, most common first):");
  const sortedReasons = [...exclusionReasonCounts.entries()].sort((a, b) => b[1] - a[1]);
  for (const [reason, count] of sortedReasons.slice(0, 15)) {
    console.log(`  ${String(count).padStart(6)}  ${reason}`);
  }
  if (sortedReasons.length > 15) {
    console.log(`  ...and ${sortedReasons.length - 15} more distinct reasons.`);
  }

  console.log(`\nRepresentative eligible examples (women + skincare/makeup/perfume):`);
  for (const category of ["skincare", "makeup", "perfume"]) {
    console.log(`  ${category}:`);
    if (eligibleExamples[category].length === 0) {
      console.log("    (none found)");
    }
    for (const ex of eligibleExamples[category]) {
      console.log(`    - "${ex.name}"${ex.brand ? ` (${ex.brand})` : ""}`);
    }
  }

  console.log(`\nExcluded examples (up to 20 of ${excluded}):`);
  for (const ex of excludedExamples) {
    console.log(`  - "${ex.name}" -> ${ex.reason}`);
  }

  console.log("");
  if (invariantViolations.length === 0) {
    console.log(
      `✓ Verified: all ${allowed} eligible products satisfy ` +
        "Beauty + Women + (Skincare OR Makeup OR Perfume)."
    );
  } else {
    console.log(
      `⚠ ${invariantViolations.length} eligible product(s) FAILED the ` +
        "Women + valid-category invariant — this indicates a classifier bug:"
    );
    for (const v of invariantViolations.slice(0, 10)) {
      console.log(`  ${v.id}: "${v.name}" ->`, v.classification);
    }
  }

  if (changedCategory.length > 0) {
    console.log(
      `\n⚠ ${changedCategory.length} product(s) would have their category ` +
        `changed by re-classification (old classifier vs. new):`
    );
    for (const c of changedCategory.slice(0, 20)) {
      console.log(`  ${c.id}: "${c.name}"  ${c.was} -> ${c.now}`);
    }
    if (changedCategory.length > 20) {
      console.log(`  ...and ${changedCategory.length - 20} more.`);
    }
  }

  if (!apply) {
    console.log(
      "\nThis was a dry run — nothing was written. Re-run with --apply " +
        "once you're happy with these numbers."
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
