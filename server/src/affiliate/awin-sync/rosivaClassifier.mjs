/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.
   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */
/**
 * ROSIVA product eligibility + classification — the single, shared
 * source of truth for turning raw Awin feed data (a *general
 * retailer* feed, not a beauty-only one) into ROSIVA's product
 * catalog. Used by the sync importer, the backfill/migration script,
 * and nothing else — every screen and the AI query the *result*
 * (`isRosivaProduct` / `rosivaCategory` / `gender` fields already
 * written to Firestore), never re-implement this logic themselves.
 *
 * ROSIVA's policy: a product is eligible (`isRosivaProduct: true`)
 * ONLY when ALL of the following hold —
 *  1. It's a genuine skincare/makeup/perfume PRODUCT, OR a genuine
 *     makeup APPLICATION tool (makeup brush, beauty blender, cosmetic
 *     applicator — these are makeup products in their own right).
 *     Precision/grooming tools that don't apply makeup (tweezers,
 *     eyelash curlers, nail/hair tools), accessories (mirrors, bags),
 *     gift boxes, hair-care items, and personal-care products (shower
 *     gel, deodorant, sanitary products, etc.) that merely mention a
 *     beauty-adjacent word are all excluded.
 *  2. It's specifically evidenced as a women's product. Explicit
 *     men's/unisex evidence always rejects. With no explicit gender
 *     wording at all, a *conservative, category-specific* inference
 *     applies (see [inferGenderForEligibility]) — never a blanket
 *     "it's beauty, so it's women's" assumption.
 *  3. Its category is exactly one of skincare/makeup/perfume.
 *
 * Accuracy is prioritized over catalog size throughout: keywords are
 * kept narrow and face/skin-specific rather than broad, and anything
 * ambiguous is excluded rather than guessed.
 */

export const ROSIVA_CATEGORIES = ["skincare", "makeup", "perfume"];

/**
 * If any of these substrings appear in the product's own category-ish
 * text (name / merchantCategory / description / tags / existing
 * category — NOT brand, see [classifyProduct]), the product is
 * excluded from ROSIVA outright, regardless of anything else. Checked
 * before the allow-list below.
 *
 * Kept deliberately specific (e.g. "vitamin supplement" rather than
 * bare "vitamin") so this doesn't reject real beauty products that
 * happen to share a word with an unrelated category — "Vitamin C
 * Serum" and "Baby Lips Lip Balm" are real product lines a bare
 * "vitamin"/"baby" match used to wrongly exclude.
 */
export const DENY_KEYWORDS = [
  // Household cleaning / laundry
  "floor cleaner", "kitchen cleaner", "kitchen degreaser", "degreaser",
  "detergent", "dishwasher", "dish soap", "washing up liquid",
  "laundry", "fabric conditioner", "fabric softener", "bleach",
  "disinfectant", "surface cleaner", "toilet cleaner", "drain cleaner",
  "oven cleaner", "glass cleaner", "multi-surface cleaner",
  "cleaning spray", "household cleaning", "cleaning product",
  "antibacterial spray", "air freshener", "polish spray", "mop",
  "bin bag", "bin liner", "corkscrew", "wine opener",

  // Personal-care products that are NOT skincare/makeup/perfume, even
  // though they share a lot of retail-category vocabulary with them
  // (this is the main gap found in the last dry-run) — a shower gel
  // or deodorant sold under a "Fragrance"/"Bath & Body" merchant
  // category would otherwise match the bare "fragrance"/"body spray"
  // allow keywords.
  "shower gel", "body wash", "deodorant", "antiperspirant",
  "anti-perspirant", "shaving", "shave gel", "shaving foam",
  "razor", "razor blade", "sanitary", "panty liner", "pantyliner",
  "sanitary towel", "sanitary pad", "sanitary pads", "tampon",
  "menstrual", "period product", "dailies", "room fragrance",
  "home fragrance", "household fragrance", "candle", "reed diffuser",
  "diffuser",
  // NOTE: deliberately NOT "fragrance-free"/"unscented"/"scent-free"
  // as deny keywords — real skincare/makeup products routinely
  // describe themselves this way as a genuine feature (sensitive-
  // skin friendly), and denying the whole product on that phrase
  // alone was rejecting real products like "Clinique iD Hydrating
  // Jelly Face Gel". The actual risk these were guarding against —
  // "fragrance-free" containing the literal word "fragrance", which
  // could otherwise misfire the *perfume* allow keyword — is handled
  // surgically in classifyProduct() instead (the phrase is neutralized
  // before category matching, not used to deny the product outright).
  // Baby products — distinct, out-of-scope vertical — are still
  // reliably caught by their own product-type words below, without
  // needing "fragrance-free" as a proxy signal.
  "soother", "pacifier", "dummy",
  // Bicycle/hardware/misc general-retail items that have been seen
  // cross-listed under a "Health & Beauty" merchant vertical despite
  // having zero actual beauty content.
  "bicycle", "bike", "bicycle bar", "hardware",
  // Cotton wool/pads/balls are a supporting supply item, not a
  // cosmetic PRODUCT — and are frequently marketed with the word
  // "cosmetic" as an adjective ("100% Cosmetic Cotton Balls"), which
  // would otherwise match a bare "cosmetic" allow keyword.
  "cotton ball", "cotton balls", "cotton pad", "cotton pads",
  "cotton wool",
  // Hand/body/foot care — ROSIVA skincare is FACIAL skincare only;
  // "cream"/"lotion"/"butter"/"oil"/"moisturizer" alone (or qualified
  // by hand/body/foot/heel/elbow) never qualifies.
  "hand cream", "hand lotion", "body lotion", "body cream",
  "body butter", "body oil", "body moisturizer", "foot cream",
  "heel cream", "elbow cream",

  // Oral care / supplements / pharmacy-unrelated
  "toothbrush", "toothpaste", "mouthwash", "dental floss", "oral care",
  "multivitamin", "vitamin supplement", "vitamin tablet", "vitamin capsule",
  "dietary supplement", "protein powder", "supplement", "medicine",
  "prescription", "painkiller", "plaster", "bandage",

  // Disambiguators for allow-list words that collide with non-beauty
  // meanings in a general retailer feed — these keep the allow
  // keyword (e.g. "toner", "face mask") usable for real beauty
  // products while excluding the specific non-beauty product it's
  // often confused with.
  "toner cartridge", "printer toner", "photocopier",
  "surgical", "medical mask", "protective mask", "face covering",
  "ppe", "3-ply", "disposable mask",
  "highlighter pen", "text highlighter", "marker pen",
  "paint primer", "wall primer", "primer paint", "primer spray paint",

  // Food / grocery
  "grocery", "snack food", "soft drink", "beverage",

  // Electronics / gadgets / sports
  "smartphone", "laptop", "desktop computer", "digital camera",
  "headphone", "bluetooth speaker", "electronics accessory", "gadget",
  "phone case", "phone charger", "sports equipment", "fitness tracker",
  "gym equipment",

  // Adult / intimate
  "sex toy", "vibrator", "intimate", "condom", "lubricant gel",
  "adult toy", "erotic",

  // Home / furniture / tools / automotive / pet / clothing / accessories
  "living room furniture", "kitchen appliance", "children's toy",
  "pet supplies", "car accessory", "power tool", "automotive",
  "baby diaper", "infant formula", "clothing", "apparel", "t-shirt",
  "trousers", "jeans", "footwear", "shoes", "trainers", "sneakers",
  "sandals", "handbag", "wallet", "jewellery", "jewelry", "sunglasses",
  "wristwatch",

  // Hair care — ROSIVA's 3 categories are skincare/makeup/perfume
  // only; hair care is a distinct, out-of-scope vertical. Bare "hair"
  // is deliberately broad (not just "hair brush"/"hair dye") because
  // it's the only reliable way to catch every hair-care phrasing —
  // "hair moisturizer", "hair serum", "hair mask", "hair oil", etc.
  // would otherwise slip through by matching the *skincare* allow
  // keywords instead. Hair-related evidence intentionally takes
  // precedence over generic cosmetic keywords — checked before any
  // allow keyword, so "Hair Serum" is denied even though "serum"-
  // adjacent phrasing would otherwise suggest skincare.
  "hair", "shampoo", "conditioner",

  // Non-makeup TOOLS/accessories/bundles — not themselves a cosmetic,
  // skincare, or perfume product. Genuine MAKEUP application tools
  // (makeup brush, beauty blender, cosmetic applicator, etc.) are
  // deliberately NOT here — they're real makeup products and are
  // allow-listed under "makeup" below instead. What stays denied here
  // is precision/grooming tools (tweezers, curlers, clippers) and
  // hair/nail tools that are never makeup application tools, plus
  // accessories (mirrors, bags) that don't apply product at all.
  "tweezers", "trimmer", "eyelash curler", "nail clipper", "nail file",
  "nail scissors", "manicure", "pedicure",
  "nail sticker", "nail stickers", "nail art sticker", "nail decal",
  "beauty device", "facial device", "cleansing device", "led mask device",
  "vanity case", "cosmetic bag", "toiletry bag", "makeup bag",
  // Deliberately NOT bare "mirror" — many genuine makeup products
  // (compacts, eyeshadow palettes) legitimately include a small
  // built-in mirror as a minor feature, and a description mentioning
  // that must not reject the whole product. Only compound phrases
  // that identify the product ITSELF as a standalone mirror do.
  "makeup mirror", "vanity mirror", "cosmetic mirror", "beauty mirror",
  "compact mirror", "handheld mirror", "gift box", "gift set",
];

/**
 * Ordered list of (category -> keywords) rules. The first rule whose
 * keywords match wins. Every keyword here must denote either an
 * actual consumable/applied product, or — for makeup specifically — a
 * genuine makeup APPLICATION tool (makeup brush, beauty blender,
 * cosmetic applicator). Precision/grooming tools that don't apply
 * product (tweezers, curlers, clippers) and hair/nail tools stay
 * denied (see [DENY_KEYWORDS]), checked first. Skincare is kept
 * narrow (face/skin-specific) rather than broad, per ROSIVA's
 * "accuracy over quantity" policy. Bare, generic words like
 * "cream"/"serum"/"mask"/"oil"/"balm"/"moisturizing" are deliberately
 * NOT listed alone — only in their face/skin-qualified compound forms
 * (e.g. "face serum", not bare "serum") so a product isn't classified
 * as skincare just because it shares a common word with a real
 * skincare product.
 */
export const CATEGORY_RULES = [
  {
    category: "skincare",
    keywords: [
      "skincare", "skin care", "face moisturi", "facial moisturi",
      "skin moisturi", "face cream", "facial cream", "face serum",
      "facial serum", "eye serum", "face gel", "facial gel",
      "facial cleanser", "face cleanser", "face wash", "toner",
      "facial toner", "exfoliat", "sunscreen", "spf", "eye cream",
      "face mask", "facial scrub", "anti-aging", "anti aging",
      "hyaluronic", "retinol", "niacinamide", "collagen", "micellar",
      "acne treatment", "blemish", "day cream", "night cream",
      "lip balm", "lipbalm", "lip care", "skin treatment", "skincare treatment",
      // Face-cleansing product FORMS, qualified by "cleansing" the same
      // way "face cream"/"face serum" are qualified rather than bare
      // ("cleansing" alone is too generic, but "cleansing lotion"/
      // "cleansing wipes" etc. are specific, real skincare product
      // types). Added because these products' own marketing copy
      // routinely says "cleanses make-up and impurities" — without this
      // qualified skincare match running FIRST, that description text
      // would otherwise false-positive-match the bare "makeup"/
      // "make-up" keyword under the makeup category below (a real bug:
      // a facial cleansing lotion/wipes product is not a makeup
      // product just because its description mentions removing makeup).
      "cleansing lotion", "cleansing wipe", "cleansing wipes",
      "cleansing gel", "cleansing foam", "cleansing balm",
      "cleansing milk", "cleansing water", "cleansing cream",
      "cleansing oil", "cleansing bar", "cleansing wash",
    ],
  },
  {
    category: "makeup",
    keywords: [
      // NOTE: deliberately no bare "cosmetic" — it's frequently used
      // as a generic adjective for supporting SUPPLIES, not actual
      // color-cosmetic products ("100% Cosmetic Cotton Balls",
      // "Cosmetic Bag"), which would otherwise match here even though
      // neither is an actual makeup product.
      "makeup", "make-up", "make up", "lipstick",
      // Both spaced and single-word forms — real listings vary
      // ("Lip Gloss" vs "Lipgloss") and word-boundary matching means
      // "lip gloss" (with a literal space) never matches "Lipgloss"
      // as one word.
      "lip gloss", "lipgloss",
      "foundation", "mascara", "eyeshadow", "eye shadow",
      "eyeliner", "eye liner", "blush", "concealer", "nail polish",
      "nail varnish", "bronzer", "highlighter", "primer",
      "setting spray", "setting powder", "face powder", "contour",
      "bb cream", "cc cream",
      "lip liner", "lipliner", "eyebrow", "brow pencil", "brow gel",
      "eyelash", "false lashes", "kohl", "compact powder", "beauty palette",
      "makeup remover", "makeup palette",
      // Genuine makeup APPLICATION tools — these apply/blend actual
      // makeup product, unlike precision/grooming tools (tweezers,
      // curlers, nail/hair tools), which stay denied.
      "makeup brush", "foundation brush", "concealer brush",
      "eyeshadow brush", "blusher brush", "blush brush",
      "eyebrow brush", "lip brush", "makeup sponge", "beauty blender",
      "cosmetic applicator", "makeup applicator",
    ],
  },
  {
    category: "perfume",
    keywords: [
      "perfume", "fragrance", "eau de parfum", "eau de toilette",
      "eau de cologne", "cologne", "parfum", "body spray", "body mist",
      "eau de", "aftershave", "edp", "edt", "women's fragrance",
      // NOTE: no "fragrance gift set" — gift sets/boxes are denied
      // outright (see DENY_KEYWORDS) unless sold as the single
      // qualifying product itself, per ROSIVA's "don't classify a
      // bundle just because it contains a beauty word" policy.
    ],
  },
];

/**
 * Keywords that are intentionally partial word-stems, matched as
 * plain substrings so every inflection is caught cheaply within their
 * already face/skin-qualified compound phrase (e.g. "face moisturi"
 * matches "face moisturizer"/"face moisturizing cream"). Every other
 * keyword is matched as a whole word/phrase (word boundary on both
 * sides) specifically so short, generic-looking words can't
 * accidentally match inside an unrelated word — e.g. bare "brow"
 * would otherwise match inside "BROWn", which is exactly the kind of
 * false positive a general retailer feed full of "Brown Leather..."
 * products would trigger constantly.
 */
const STEM_KEYWORDS = new Set([
  "exfoliat",
  "face moisturi", "facial moisturi", "skin moisturi",
]);

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

const wordBoundaryCache = new Map();

function keywordMatches(haystack, keyword) {
  if (STEM_KEYWORDS.has(keyword)) {
    return haystack.includes(keyword);
  }
  let pattern = wordBoundaryCache.get(keyword);
  if (!pattern) {
    pattern = new RegExp(`\\b${escapeRegExp(keyword)}\\b`);
    wordBoundaryCache.set(keyword, pattern);
  }
  return pattern.test(haystack);
}

function findMatch(haystack, keywords) {
  return keywords.find((keyword) => keywordMatches(haystack, keyword));
}

const FRAGRANCE_FREE_PATTERN = /\bfragrance[\s-]free\b/g;
const SCENT_FREE_PATTERN = /\bscent[\s-]free\b/g;
const UNSCENTED_PATTERN = /\bunscented\b/g;

/**
 * Neutralizes "fragrance-free"/"scent-free"/"unscented" before
 * category matching — these phrases are the OPPOSITE of a fragrance
 * product, but "fragrance-free" literally contains the word
 * "fragrance", which would otherwise misfire the perfume allow
 * keyword. This only affects what counts as a positive category
 * match; it never denies a product outright (real skincare/makeup
 * products routinely advertise themselves as fragrance-free/
 * unscented as a genuine feature, and that alone must not exclude
 * them — see classifyProduct's module doc).
 * @param {string} haystack Already-lowercased text.
 * @return {string}
 */
function neutralizeFragranceFreeWording(haystack) {
  return haystack
    .replace(FRAGRANCE_FREE_PATTERN, " ")
    .replace(SCENT_FREE_PATTERN, " ")
    .replace(UNSCENTED_PATTERN, " ");
}

const MEN_PATTERN = /\b(for\s+him|men'?s?|man'?s?)\b/;
const WOMEN_PATTERN = /\b(for\s+her|women'?s?|woman'?s?|ladies'?|female)\b/;
const UNISEX_PATTERN = /\bunisex\b/;

/**
 * Reads *only explicit* gender wording from the text — never an
 * inference. `"unknown"` genuinely means "no explicit gender wording
 * found", and is a distinct question from whether ROSIVA should still
 * treat the product as eligible (see [inferGenderForEligibility]).
 *
 * Word-boundary regex (not plain substring) specifically so "women's"
 * is never misread as containing "men" — `\bmen\b` cannot match
 * inside "women" because there's no word boundary between the "o" and
 * the "m".
 * @param {string} haystack Already-lowercased text.
 * @return {"women"|"men"|"unisex"|"unknown"}
 */
export function classifyGender(haystack) {
  const hasUnisex = UNISEX_PATTERN.test(haystack);
  const hasWomen = WOMEN_PATTERN.test(haystack);
  const hasMen = MEN_PATTERN.test(haystack);

  if (hasUnisex || (hasWomen && hasMen)) return "unisex";
  if (hasMen) return "men";
  if (hasWomen) return "women";
  return "unknown";
}

/**
 * Categories where, in real retail data, the *absence* of any men's/
 * unisex wording is itself reasonably strong circumstantial evidence
 * of women's targeting — color cosmetics and mainline skincare
 * listings that don't explicitly flag themselves "for men"/"unisex"
 * are, in practice, overwhelmingly women's lines (explicit men's
 * makeup/skincare is itself a distinct, clearly-labeled retail
 * category). Perfume is deliberately excluded from this inference:
 * fragrance is marketed far more evenly across explicit men's/
 * women's/unisex lines in general retail, so "no explicit wording"
 * carries much weaker signal there and must NOT be assumed women's.
 */
const CATEGORIES_ELIGIBLE_FOR_WOMEN_INFERENCE = new Set(["skincare", "makeup"]);

/**
 * Decides the *eligibility* gender for a product already matched to a
 * ROSIVA category — distinct from [classifyGender]'s raw text
 * reading. Explicit women's evidence always wins; explicit men's/
 * unisex evidence always rejects. Only when there's no explicit
 * wording at all does this apply the conservative, category-scoped
 * inference above.
 * @param {"women"|"men"|"unisex"|"unknown"} rawGender
 * @param {string} rosivaCategory
 * @return {{gender: "women"|"men"|"unisex"|"unknown", inferred: boolean}}
 */
function inferGenderForEligibility(rawGender, rosivaCategory) {
  if (rawGender !== "unknown") {
    return {gender: rawGender, inferred: false};
  }
  if (CATEGORIES_ELIGIBLE_FOR_WOMEN_INFERENCE.has(rosivaCategory)) {
    return {gender: "women", inferred: true};
  }
  return {gender: "unknown", inferred: false};
}

/**
 * Classifies a single Awin product for ROSIVA: is it in scope at all
 * (`isRosivaProduct`), which of the 3 canonical categories it belongs
 * to (`rosivaCategory`), and who it's marketed at (`gender`).
 *
 * `isRosivaProduct` requires BOTH a genuine category match AND
 * `gender === "women"` (explicit or conservatively inferred per
 * [inferGenderForEligibility] — never a blanket "it's beauty, so it's
 * women's" assumption). Men's and unisex products are excluded from
 * `isRosivaProduct` even when the category match itself is perfect;
 * `rosivaCategory` is still recorded on every category-matched
 * product regardless (so a future men's/unisex catalog could reuse
 * this same data without re-classifying) — `gender` stores the FINAL
 * (possibly inferred) value used for the eligibility decision, with
 * the inference itself always visible in `classificationReason`.
 *
 * DENY-checking and CATEGORY-matching deliberately look at different
 * text:
 *  - Deny-checking uses EVERY field (name, merchantCategory,
 *    description, existing category, tags) — a general retailer's
 *    metadata noise is itself a reliable negative signal wherever it
 *    appears, and excluding too eagerly is the safer failure mode.
 *  - Category-matching (what actually decides skincare/makeup/
 *    perfume) uses ONLY the product's own identity — name and
 *    description — never merchant/existing category or tags. Merchant
 *    taxonomy in a general retailer feed is frequently noisy or
 *    outright mismatched (a bicycle accessory cross-listed under a
 *    "Health & Beauty" vertical, existing category data left over
 *    from an earlier, looser classifier pass), so it must never be
 *    the SOLE basis for deciding what a product actually is. Brand is
 *    consulted only as a last resort, when name+description alone
 *    found nothing at all — still weaker than identity, but stronger
 *    than merchant taxonomy, since a brand name is at least part of
 *    the product's own identity rather than a retailer's categorization
 *    of it.
 *
 * This means "brand = 'Some Beauty Brand', name = 'Kitchen Cleaner'"
 * is excluded purely on the name evidence (brand is never even
 * reached, since the name itself already denies it), and "brand =
 * 'W7', name = 'Eyelust Mascara'" is classified purely on the name
 * matching "mascara" — brand was never needed there either, which is
 * exactly the point: real matches almost always come from the
 * product's own name.
 *
 * @param {object} product
 * @param {string} [product.name]
 * @param {string} [product.merchantCategory]
 * @param {string} [product.description]
 * @param {string} [product.brand]
 * @param {string} [product.category] Awin's own/existing category text.
 * @param {string} [product.tags]
 * @return {{
 *   isRosivaProduct: boolean,
 *   rosivaCategory: string|null,
 *   gender: "women"|"men"|"unisex"|"unknown",
 *   classificationReason: string,
 * }}
 */
export function classifyProduct({
  name,
  merchantCategory,
  description,
  brand,
  category,
  tags,
} = {}) {
  // Broad — every field — for deny-checking only.
  const fullHaystack = [name, merchantCategory, description, category, tags]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  // Narrow — the product's own identity, name + description ONLY —
  // for deciding what the product actually IS. Never merchant/
  // existing category, never tags: that's exactly the untrusted
  // metadata this narrowing exists to ignore. "fragrance-free"/
  // "unscented" wording is neutralized here (not denied — see
  // neutralizeFragranceFreeWording) so it can't misfire the perfume
  // keyword while every other real signal in the text still applies
  // normally.
  const identityHaystack = neutralizeFragranceFreeWording(
    [name, description].filter(Boolean).join(" ").toLowerCase()
  );

  const deniedKeyword = findMatch(fullHaystack, DENY_KEYWORDS);
  if (deniedKeyword) {
    return {
      isRosivaProduct: false,
      rosivaCategory: null,
      gender: classifyGender(fullHaystack),
      classificationReason: `denied: matched "${deniedKeyword}"`,
    };
  }

  for (const rule of CATEGORY_RULES) {
    const matchedKeyword = findMatch(identityHaystack, rule.keywords);
    if (matchedKeyword) {
      const rawGender = classifyGender(fullHaystack);
      const {gender, inferred} = inferGenderForEligibility(rawGender, rule.category);
      const eligible = gender === "women";
      return {
        isRosivaProduct: eligible,
        rosivaCategory: rule.category,
        gender,
        classificationReason: eligible
          ? `matched "${matchedKeyword}" in product title/description -> ${rule.category}` +
            (inferred ? " (women inferred: no contrary gender evidence)" : " (explicit women)")
          : `matched "${matchedKeyword}" in product title/description -> ${rule.category}, but gender=${gender} (women-only catalog)`,
      };
    }
  }

  // Name+description alone found nothing — brand is consulted only
  // now, as a last-resort, weaker signal (flagged as such in
  // classificationReason so it stays auditable/reviewable). Still
  // never merchant category/tags — those remain untrusted throughout.
  if (brand) {
    const brandHaystack = brand.toLowerCase();
    for (const rule of CATEGORY_RULES) {
      const matchedKeyword = findMatch(brandHaystack, rule.keywords);
      if (matchedKeyword) {
        const rawGender = classifyGender(fullHaystack + " " + brandHaystack);
        const {gender, inferred} = inferGenderForEligibility(rawGender, rule.category);
        const eligible = gender === "women";
        return {
          isRosivaProduct: eligible,
          rosivaCategory: rule.category,
          gender,
          classificationReason: eligible
            ? `weak match: brand only matched "${matchedKeyword}" -> ${rule.category}` +
              (inferred ? " (women inferred: no contrary gender evidence)" : " (explicit women)")
            : `weak match: brand only matched "${matchedKeyword}" -> ${rule.category}, but gender=${gender} (women-only catalog)`,
        };
      }
    }
  }

  return {
    isRosivaProduct: false,
    rosivaCategory: null,
    gender: classifyGender(fullHaystack),
    classificationReason: "no category keyword matched in product title/description",
  };
}
