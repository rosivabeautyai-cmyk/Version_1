import { getDb } from '../firebase.js';
import { ALLOWED_CATEGORIES, REQUIRED_GENDER, toEnglishHaystack } from '../intent/normalize.js';

/**
 * Firestore is the source of truth for products. This module is the
 * ONLY place the AI flow reads products, and every read here is
 * unconditionally constrained to ROSIVA's women's-beauty scope:
 *
 *   isRosivaProduct === true
 *   gender === "women"
 *   rosivaCategory ∈ {skincare, makeup, perfume}
 *
 * These constraints are applied by THIS code, never by anything the
 * LLM returned. The LLM's category only picks which of the three
 * allowed categories to search; it can never widen or remove a
 * filter, and product identity/price/url/image always come straight
 * from the Firestore document.
 *
 * `isRosivaProduct == true` + `rosivaCategory ==` + `orderBy rating`
 * runs server-side (a composite index already exists — see
 * firestore.indexes.json); `gender == "women"` is a post-fetch filter
 * to avoid needing an extra composite index, exactly as the Flutter
 * `ProductApiService` already does.
 */

const PRODUCTS_COLLECTION = 'products';

/** Rows fetched per Firestore query before local filtering/ranking. */
const FETCH_LIMIT = 80;

/**
 * Minimal, safe product shape for the client. No description /
 * ingredients / internal fields.
 */
function toClientProduct(id, data) {
  const d = data || {};
  return {
    id: String(d.id || d.productId || id || ''),
    name: d.name || '',
    brand: d.brand || null,
    price:
      typeof d.price === 'number'
        ? d.price
        : d.price != null
          ? Number(d.price) || null
          : null,
    currency: d.currency || 'USD',
    imageUrl: d.imageUrl || d.image || null,
    rating: typeof d.rating === 'number' ? d.rating : null,
    category: d.rosivaCategory || d.category || null,
    storeUrl: d.storeUrl || d.url || null,
    inStock: d.inStock !== false,
    isEditorsChoice: d.isEditorsChoice === true,
    // Echoed so the client can defensively re-verify.
    isRosivaProduct: d.isRosivaProduct === true,
    gender: d.gender || 'unknown',
  };
}

/**
 * Independent, in-code re-application of every hard filter on already
 * fetched rows. Defense in depth.
 */
export function passesHardFilters(p) {
  return (
    p.isRosivaProduct === true &&
    p.gender === REQUIRED_GENDER &&
    ALLOWED_CATEGORIES.includes(p.category)
  );
}

/**
 * @return {Promise<Array<{product: object, tags: string[]}>>}
 */
async function runCategoryQuery(db, category) {
  const snap = await db
    .collection(PRODUCTS_COLLECTION)
    .where('isRosivaProduct', '==', true)
    .where('rosivaCategory', '==', category)
    .orderBy('rating', 'desc')
    .limit(FETCH_LIMIT)
    .get();

  return (snap.docs || [])
    .map((doc) => {
      const data = doc.data() || {};
      return {
        product: toClientProduct(doc.id, data),
        tags: Array.isArray(data.tags) ? data.tags.filter((t) => typeof t === 'string') : [],
      };
    })
    .filter((row) => passesHardFilters(row.product));
}

function matchesTerm(row, term) {
  if (!term) return true;
  const haystack = [row.product.name, row.product.brand, row.product.category, ...row.tags]
    .filter((v) => typeof v === 'string')
    .join(' ')
    .toLowerCase();
  return haystack.includes(term);
}

/**
 * Two-stage search. Stage 2 NEVER widens beyond the intent's category
 * — it only drops the free-text term. A request with no category
 * returns [] (caller treats it as "no ROSIVA category").
 *
 * @param {object} opts
 * @param {'skincare'|'makeup'|'perfume'|null} opts.category
 * @param {string|null} opts.productType
 * @param {string[]} [opts.attributes]
 * @param {string} [opts.rawMessage]
 * @param {*} [opts._db] test seam
 * @return {Promise<{products: object[], stage: 0|1|2}>}
 */
export async function searchProducts({ category, productType, rawMessage = '', _db }) {
  if (!category || !ALLOWED_CATEGORIES.includes(category)) {
    return { products: [], stage: 0 };
  }

  const db = _db || getDb();

  let term = (productType || '').toLowerCase().trim();
  if (!term) {
    const { mappedTerm } = toEnglishHaystack(rawMessage);
    term = (mappedTerm || '').toLowerCase();
  }
  if (term === category) term = ''; // a bare category word is not a narrow filter

  const pool = await runCategoryQuery(db, category);

  // Stage 1: narrow — category + term.
  if (term) {
    const narrowed = pool.filter((row) => matchesTerm(row, term));
    if (narrowed.length > 0) {
      return { products: narrowed.map((r) => r.product), stage: 1 };
    }
  }

  // Stage 2: fallback — same category, term dropped.
  return { products: pool.map((r) => r.product), stage: 2 };
}
