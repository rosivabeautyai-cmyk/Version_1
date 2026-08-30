/**
 * Deterministic intent normalization + LLM-output sanitization.
 *
 * This module is the SAFETY LAYER. The LLM is only ever used to help
 * fill in a structured intent; every value it returns passes through
 * here before anything touches Firestore. The backend — not the LLM —
 * decides the final category, always forces `gender = "women"`, and
 * decides whether a request is out of ROSIVA's scope.
 */

export const ALLOWED_CATEGORIES = ['skincare', 'makeup', 'perfume'];
export const REQUIRED_GENDER = 'women';

/**
 * Arabic (mostly Egyptian-dialect) beauty terms -> the single English
 * word the catalog stores. Superset of the Flutter
 * `search_term_normalizer.dart` map — kept in sync intentionally, with
 * extra colloquial variants the AI flow sees.
 */
const AR_TERM_TO_EN = {
  'ماسكرا': 'mascara',
  'ماسكرة': 'mascara',
  'مسكرة': 'mascara',
  'روج': 'lipstick',
  'أحمر شفاه': 'lipstick',
  'احمر شفاه': 'lipstick',
  'ليب جلوس': 'lip gloss',
  'جلوس': 'lip gloss',
  'ايلاينر': 'eyeliner',
  'آيلاينر': 'eyeliner',
  'إيلاينر': 'eyeliner',
  'كحل': 'eyeliner',
  'هايلايتر': 'highlighter',
  'هيلايتر': 'highlighter',
  'كونسيلر': 'concealer',
  'كوريكتور': 'concealer',
  'فاونديشن': 'foundation',
  'كريم اساس': 'foundation',
  'كريم أساس': 'foundation',
  'بودرة': 'face powder',
  'بلاشر': 'blush',
  'بلاش': 'blush',
  'برونزر': 'bronzer',
  'ظلال': 'eyeshadow',
  'ايشادو': 'eyeshadow',
  'اظافر': 'nail polish',
  'مناكير': 'nail polish',
  'عطر': 'perfume',
  'برفان': 'perfume',
  'برفيوم': 'perfume',
  'عطور': 'perfume',
  'سيروم': 'face serum',
  'مرطب': 'face moisturizer',
  'مرطب للوجه': 'face moisturizer',
  'غسول': 'face wash',
  'غسول وجه': 'face wash',
  'تونر': 'toner',
  'واقي شمس': 'sunscreen',
  'واقي الشمس': 'sunscreen',
  'صن بلوك': 'sunscreen',
  'ماسك': 'face mask',
  'مقشر': 'exfoliator',
  'كريم عيون': 'eye cream',
  'بلسم شفاه': 'lip balm',
  'بلسم شفايف': 'lip balm',
  'مرطب شفاه': 'lip balm',
  'روتين عناية بالبشرة': 'skincare routine',
  'روتين العناية بالبشرة': 'skincare routine',
  'روتين للبشرة': 'skincare routine',
  'عناية بالبشرة': 'skincare',
  'عناية للبشرة': 'skincare',
  'مكياج': 'makeup',
  'ميكب': 'makeup',
  'فرش مكياج': 'makeup brush',
  'فرشاة مكياج': 'makeup brush',
  'فرش المكياج': 'makeup brush',
  'فرشة مكياج': 'makeup brush',
  'اسفنجة مكياج': 'makeup sponge',
  'بيوتي بلندر': 'beauty blender',
};

/**
 * Product-type keyword (English, lowercase) -> canonical category.
 * Order matters only for readability; matching is whole-word-ish.
 */
const PRODUCT_TYPE_TO_CATEGORY = {
  // makeup
  'mascara': 'makeup',
  'lipstick': 'makeup',
  'lip gloss': 'makeup',
  'lipgloss': 'makeup',
  'lip liner': 'makeup',
  'eyeliner': 'makeup',
  'eye liner': 'makeup',
  'kohl': 'makeup',
  'highlighter': 'makeup',
  'bronzer': 'makeup',
  'blush': 'makeup',
  'blusher': 'makeup',
  'concealer': 'makeup',
  'foundation': 'makeup',
  'face powder': 'makeup',
  'setting powder': 'makeup',
  'setting spray': 'makeup',
  'contour': 'makeup',
  'eyeshadow': 'makeup',
  'eye shadow': 'makeup',
  'eyebrow': 'makeup',
  'brow pencil': 'makeup',
  'nail polish': 'makeup',
  'nail varnish': 'makeup',
  'bb cream': 'makeup',
  'cc cream': 'makeup',
  'primer': 'makeup',
  'makeup': 'makeup',
  'make up': 'makeup',
  'make-up': 'makeup',
  'makeup brush': 'makeup',
  'makeup sponge': 'makeup',
  'beauty blender': 'makeup',
  'makeup remover': 'makeup',
  'false lashes': 'makeup',
  'eyelash': 'makeup',
  // skincare
  'skincare': 'skincare',
  'skin care': 'skincare',
  'skincare routine': 'skincare',
  'face serum': 'skincare',
  'facial serum': 'skincare',
  'serum': 'skincare',
  'face moisturizer': 'skincare',
  'moisturizer': 'skincare',
  'face cream': 'skincare',
  'face wash': 'skincare',
  'face cleanser': 'skincare',
  'cleanser': 'skincare',
  'toner': 'skincare',
  'sunscreen': 'skincare',
  'spf': 'skincare',
  'face mask': 'skincare',
  'sheet mask': 'skincare',
  'exfoliator': 'skincare',
  'exfoliant': 'skincare',
  'scrub': 'skincare',
  'eye cream': 'skincare',
  'retinol': 'skincare',
  'hyaluronic acid': 'skincare',
  'niacinamide': 'skincare',
  'vitamin c serum': 'skincare',
  'lip balm': 'skincare',
  'day cream': 'skincare',
  'night cream': 'skincare',
  // perfume
  'perfume': 'perfume',
  'fragrance': 'perfume',
  'eau de parfum': 'perfume',
  'eau de toilette': 'perfume',
  'edp': 'perfume',
  'edt': 'perfume',
  'body mist': 'perfume',
  'body spray': 'perfume',
};

/**
 * Substrings that put a request OUT of ROSIVA's scope regardless of
 * anything the LLM says. Mirrors the classifier's DENY intent, plus a
 * few Arabic terms. Checked against the raw lowercased user message.
 */
const UNSUPPORTED_PATTERNS = [
  // hair (bare "hair" handled by HAIR_PATTERN below so it doesn't
  // false-match inside another word)
  'shampoo', 'conditioner', 'hairspray', 'hair spray',
  'شامبو', 'بلسم شعر', 'بلسم للشعر', 'صبغة شعر', 'صبغه شعر', 'مثبت شعر',
  // personal / body care that isn't facial skincare / makeup / perfume
  'deodorant', 'antiperspirant', 'shower gel', 'body wash', 'body lotion',
  'body cream', 'hand cream', 'foot cream', 'soap bar', 'bar soap',
  'shaving', 'shave gel', 'aftershave balm', 'razor', 'wax strips',
  'مزيل عرق', 'مزيل العرق', 'جل استحمام', 'صابون', 'لوشن جسم', 'كريم يدين',
  'حلاقة', 'شفرة حلاقة', 'إزالة شعر', 'ازالة الشعر',
  // oral / supplements / household / misc
  'toothpaste', 'toothbrush', 'mouthwash', 'supplement', 'vitamin tablet',
  'detergent', 'cleaning spray', 'cleaning product', 'air freshener',
  'candle', 'diffuser', 'household', 'dish soap', 'washing up liquid',
  'laundry', 'floor cleaner', 'kitchen cleaner',
  'معجون اسنان', 'فرشاة اسنان', 'مكمل غذائي', 'منظف', 'معطر جو', 'شمعة',
  'منتجات منزلية', 'منتجات منزليه', 'ادوات منزلية', 'مسحوق غسيل', 'صابون اطباق',
  // tools/accessories that aren't makeup application tools
  'tweezers', 'nail clipper', 'eyelash curler', 'hair straightener',
  'hair dryer', 'curling iron',
];

/**
 * Bare "hair" as a whole word -> out of scope (mirrors the classifier's
 * DENY on "hair"). Word-boundary so it never fires inside "chair",
 * "hairline"-free product copy, etc. Arabic "شعر" only as a standalone
 * token (it also means "poetry"; as a substring it risks false hits).
 */
const HAIR_PATTERN = /\bhair\b/;
const AR_HAIR_PATTERN = /(^|[\s،.])شعر([\s،.]|$)|للشعر|بالشعر/;

/** Explicit non-women targeting anywhere in the message -> reject. */
const MEN_PATTERN = /\b(for\s+him|men'?s|man'?s|male|guys?|husband|boyfriend)\b/;
const UNISEX_PATTERN = /\b(unisex|for\s+everyone|any\s+gender|gender[- ]?neutral)\b/;
const AR_MEN_PATTERN = /(رجالي|للرجال|رجالى|زوجي|زوجى|رجل)/;
const AR_UNISEX_PATTERN = /(للجنسين|يونيسكس|للكل|مشترك)/;

/** Attribute keywords worth carrying into ranking. */
const ATTRIBUTE_KEYWORDS = [
  'waterproof', 'matte', 'long lasting', 'long-lasting', 'longwear',
  'volumizing', 'lengthening', 'hydrating', 'oil free', 'oil-free',
  'oily skin', 'dry skin', 'sensitive skin', 'anti aging', 'anti-aging',
  'brightening', 'natural', 'vegan', 'cruelty free', 'cruelty-free',
  'travel size', 'mini',
];
const AR_ATTRIBUTE_TO_EN = {
  'ضد الميه': 'waterproof',
  'ضد الماء': 'waterproof',
  'مقاوم للماء': 'waterproof',
  'مط': 'matte',
  'مطفي': 'matte',
  'ثابت': 'long lasting',
  'يدوم طويلا': 'long lasting',
  'للبشرة الدهنية': 'oily skin',
  'للبشرة الجافة': 'dry skin',
  'للبشرة الحساسة': 'sensitive skin',
  'مرطب': 'hydrating',
  'تفتيح': 'brightening',
};

/**
 * Canonical category from any raw string. Mirrors the Flutter
 * `normalizeCategory` (category_model.dart) exactly.
 * @param {*} raw
 * @return {'skincare'|'makeup'|'perfume'|null}
 */
export function normalizeCategory(raw) {
  if (raw == null) return null;
  const value = String(raw).trim().toLowerCase().replace(/[-_]+/g, ' ');
  if (!value) return null;
  if (ALLOWED_CATEGORIES.includes(value)) return value;
  if (value.includes('makeup') || value.includes('make up') || value.includes('cosmetic')) {
    return 'makeup';
  }
  if (value.includes('skincare') || value.includes('skin care')) return 'skincare';
  if (
    value.includes('perfume') ||
    value.includes('fragrance') ||
    value.includes('parfum') ||
    value.includes('cologne')
  ) {
    return 'perfume';
  }
  return null;
}

/**
 * Translate a raw (possibly Arabic / mixed) message into a lowercased
 * English-ish search haystack, applying the Arabic term map.
 * @param {string} message
 * @return {{haystack: string, mappedTerm: string|null}}
 */
export function toEnglishHaystack(message) {
  const lower = String(message || '').toLowerCase().trim();
  let mappedTerm = null;
  let haystack = lower;
  // Longest keys first so "روتين عناية بالبشرة" wins over "عناية
  // بالبشرة", AND consume each match so a shorter key that is a
  // substring of a longer one can't also fire — e.g. "ماسك" (face
  // mask) must NOT match inside "ماسكرا" (mascara).
  let remaining = lower;
  const keys = Object.keys(AR_TERM_TO_EN).sort((a, b) => b.length - a.length);
  for (const key of keys) {
    if (remaining.includes(key)) {
      const en = AR_TERM_TO_EN[key];
      if (!mappedTerm) mappedTerm = en;
      haystack += ` ${en}`;
      remaining = remaining.split(key).join(' ');
    }
  }
  return { haystack, mappedTerm };
}

function detectAttributes(message, haystack) {
  const found = new Set();
  for (const kw of ATTRIBUTE_KEYWORDS) {
    if (haystack.includes(kw)) found.add(kw.replace('-', ' '));
  }
  for (const [ar, en] of Object.entries(AR_ATTRIBUTE_TO_EN)) {
    if (String(message).includes(ar)) found.add(en);
  }
  return [...found].slice(0, 5);
}

/**
 * Signals that the message is a *refinement* of an earlier request
 * rather than a fresh product request: a budget, a comparative, a
 * selection ("the first one"). Attribute words ("waterproof", "matte",
 * "ضد الميه") are detected separately via `det.attributes`.
 */
const REFINEMENT_PATTERNS = [
  /\b(cheaper|cheapest|pricier|more expensive|another|other one|a different one|instead|the (first|second|third|last|next|\w+) one|smaller|bigger|lighter|darker|stronger|milder|more affordable)\b/i,
  /\b(under|below|less than|no more than|max|maximum|budget|around|about)\b\s*\$?\s*\d/i,
  /^\s*\$?\s*\d+\s*(usd|egp|aed|sar|dollars?|جنيه|ريال|درهم)?\s*$/i,
  /(أرخص|أغلى|تاني|غيره|بدل|في حدود|أقل من|حوالي|كمان واحد|واحد تاني)/,
];

/**
 * Is `message` a bare refinement of an earlier request? True only when
 * the deterministic pass found NO product of its own AND the message
 * is just a modifier — an attribute (waterproof / matte / for oily
 * skin / ضد الميه …), a budget, or a comparative ("a cheaper one" /
 * "تاني"). A message that contains a real product word is never "just
 * a refinement", so this can never hijack a fresh request.
 * @param {string} message
 * @param {{category:?string, productType:?string, attributes:string[]}} det
 * @return {boolean}
 */
export function isRefinementFollowUp(message, det) {
  if (!det || det.category || det.productType) return false;
  if (Array.isArray(det.attributes) && det.attributes.length > 0) return true;
  const m = String(message || '').trim();
  if (!m) return false;
  return REFINEMENT_PATTERNS.some((re) => re.test(m));
}

/**
 * Walks the conversation history backwards and returns the most recent
 * *user* turn that, on its own, yields a concrete ROSIVA category —
 * i.e. the request a bare follow-up would be refining. The value is
 * always one of ALLOWED_CATEGORIES (it comes from `deterministicIntent`),
 * so inheriting it can never widen scope.
 * @param {Array<{role?:string, text?:string}>} history
 * @return {{category:'skincare'|'makeup'|'perfume', productType:string|null}|null}
 */
export function derivePriorIntent(history) {
  if (!Array.isArray(history)) return null;
  for (let i = history.length - 1; i >= 0; i--) {
    const turn = history[i];
    if (!turn || typeof turn.text !== 'string' || turn.role === 'assistant') continue;
    const d = deterministicIntent(turn.text);
    if (!d.unsupported && d.category) {
      return { category: d.category, productType: d.productType };
    }
  }
  return null;
}

function matchProductType(haystack) {
  // Prefer the longest matching key (e.g. "lip gloss" over "lip").
  const keys = Object.keys(PRODUCT_TYPE_TO_CATEGORY).sort((a, b) => b.length - a.length);
  for (const key of keys) {
    const re = new RegExp(`(^|[^a-z])${key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}([^a-z]|$)`);
    if (re.test(haystack)) {
      return { productType: key, category: PRODUCT_TYPE_TO_CATEGORY[key] };
    }
  }
  return { productType: null, category: null };
}

/**
 * Pure deterministic pass over the raw user message. Never calls the
 * LLM. Good enough on its own for the common cases (and every unit
 * test in test/intent.test.js).
 *
 * @param {string} message
 * @return {{
 *   category: 'skincare'|'makeup'|'perfume'|null,
 *   productType: string|null,
 *   attributes: string[],
 *   unsupported: boolean,
 *   reason: string,
 * }}
 */
export function deterministicIntent(message) {
  const raw = String(message || '');
  const lower = raw.toLowerCase();
  const { haystack, mappedTerm } = toEnglishHaystack(raw);

  // 1. Explicit non-women targeting -> out of scope.
  if (MEN_PATTERN.test(lower) || AR_MEN_PATTERN.test(raw)) {
    return {
      category: null, productType: null, attributes: [],
      unsupported: true, reason: 'mens-product',
    };
  }
  if (UNISEX_PATTERN.test(lower) || AR_UNISEX_PATTERN.test(raw)) {
    return {
      category: null, productType: null, attributes: [],
      unsupported: true, reason: 'unisex-product',
    };
  }

  // 2. Out-of-scope product classes (hair, body care, household, ...).
  if (HAIR_PATTERN.test(lower) || AR_HAIR_PATTERN.test(raw)) {
    return {
      category: null, productType: null, attributes: [],
      unsupported: true, reason: 'unsupported-term:hair',
    };
  }
  for (const pat of UNSUPPORTED_PATTERNS) {
    if (lower.includes(pat) || raw.includes(pat)) {
      return {
        category: null, productType: null, attributes: [],
        unsupported: true, reason: `unsupported-term:${pat.trim()}`,
      };
    }
  }

  // 3. Product type + category.
  const attributes = detectAttributes(raw, haystack);
  const typed = matchProductType(haystack);
  let category = typed.category;
  let productType = typed.productType || mappedTerm;

  // 4. Bare category words if no specific type found.
  if (!category) {
    category =
      normalizeCategory(lower) ||
      (/(بشرة|بشره)/.test(raw) ? 'skincare' : null) ||
      (/(مكياج|ميكب)/.test(raw) ? 'makeup' : null) ||
      (/(عطر|برفان|برفيوم)/.test(raw) ? 'perfume' : null);
  }

  // Normalize a routine phrasing.
  if (productType === 'skincare routine' || /routine/.test(haystack)) {
    if (!category) category = 'skincare';
  }
  if (productType === 'skincare' || productType === 'makeup') {
    // "I want skincare" — category is enough, no narrow product type.
    if (!category) category = productType;
    productType = null;
  }

  return {
    category: category || null,
    productType: productType ? String(productType).slice(0, 40) : null,
    attributes,
    unsupported: false,
    reason: category || productType ? 'matched' : 'no-match',
  };
}

/**
 * Merge the LLM's structured guess with the deterministic pass and
 * clamp everything to what the backend is willing to act on.
 *
 * HARD RULES enforced here (the LLM cannot override any of them):
 *  - final category MUST be one of ALLOWED_CATEGORIES or null
 *  - if the deterministic pass says the request is unsupported, it IS
 *    unsupported — the LLM cannot re-open it
 *  - `gender` in the returned intent is ALWAYS "women"; the LLM's
 *    gender / isRosivaProduct / product-id fields are ignored entirely
 *
 * @param {object|null} llm  raw parsed JSON from the model (untrusted)
 * @param {ReturnType<typeof deterministicIntent>} det
 * @param {{category:string, productType:?string}|null} [prior]  most
 *        recent categorized request from history (for follow-ups)
 * @param {string} [message]  the raw current message (refinement check)
 * @return {{
 *   category: 'skincare'|'makeup'|'perfume'|null,
 *   productType: string|null,
 *   attributes: string[],
 *   gender: 'women',
 *   unsupported: boolean,
 *   reason: string,
 * }}
 */
export function sanitizeIntent(llm, det, prior = null, message = '') {
  if (det.unsupported) {
    return {
      category: null, productType: null, attributes: [],
      gender: REQUIRED_GENDER, unsupported: true, reason: det.reason,
    };
  }

  const llmObj = llm && typeof llm === 'object' ? llm : {};

  // The deterministic category is trusted first (it already refused
  // men's/unisex/out-of-scope above). Only fall back to the LLM's when
  // deterministic found none.
  const llmCategory = normalizeCategory(llmObj.category);
  let category = det.category || (ALLOWED_CATEGORIES.includes(llmCategory) ? llmCategory : null);

  let productType = det.productType;
  if (!productType && typeof llmObj.productType === 'string' && llmObj.productType.trim()) {
    productType = llmObj.productType.trim().toLowerCase().slice(0, 40);
  }

  const attributes = new Set(det.attributes);
  if (Array.isArray(llmObj.attributes)) {
    for (const a of llmObj.attributes) {
      if (typeof a === 'string' && a.trim()) attributes.add(a.trim().toLowerCase());
    }
  }

  // Follow-up refinement: a bare modifier ("waterproof", "a cheaper
  // one", "ضد الميه") with no product of its own inherits the
  // category/productType of the request it refines. `prior.category`
  // is always one of the three allowed categories, so this can never
  // widen scope, expose men's/unisex, or bypass any hard filter — the
  // Firestore search still applies every constraint independently.
  // With no prior context (nothing to refine), a bare "waterproof"
  // still resolves to nothing.
  let inheritedFromPrior = false;
  if (!category && !productType && prior && isRefinementFollowUp(message, det)) {
    category = prior.category;
    productType = prior.productType || null;
    inheritedFromPrior = true;
  }

  // If, after all of that, we still have neither a category nor a
  // usable product type, the request is unsupported (e.g. "عايزة شامبو"
  // that slipped past the pattern list, or pure chit-chat routed here).
  const llmSaysUnsupported = llmObj.unsupported === true;
  const unsupported = inheritedFromPrior
    ? false
    : ((!category && !productType) || (llmSaysUnsupported && !category));

  return {
    category: unsupported ? null : category,
    productType: unsupported ? null : (productType || null),
    attributes: [...attributes].slice(0, 5),
    gender: REQUIRED_GENDER,
    unsupported,
    reason: unsupported
      ? (llmSaysUnsupported ? 'llm-unsupported' : 'no-actionable-intent')
      : (inheritedFromPrior ? 'refined-from-context' : (det.reason || 'llm-assisted')),
  };
}
