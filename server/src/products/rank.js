/**
 * Deterministic, backend-only ranking. The LLM never orders or filters
 * products. Ordering factors (high to low weight):
 *   1. exact productType word in name
 *   2. productType word anywhere (brand / category)
 *   3. each matched attribute
 *   4. editor's choice
 *   5. rating
 *   6. has a working store URL
 *   7. in stock
 * Stable: ties keep the incoming (rating-desc) order.
 */

/**
 * @param {object[]} products  client-shaped products from searchProducts
 * @param {object} opts
 * @param {string|null} opts.productType
 * @param {string[]} [opts.attributes]
 * @param {number} [opts.limit]
 * @return {object[]}
 */
export function rankProducts(products, { productType, attributes = [], limit = 6 }) {
  const type = (productType || '').toLowerCase().trim();
  const attrs = attributes.map((a) => a.toLowerCase()).filter(Boolean);

  const scored = products.map((p, index) => {
    let score = 0;
    const name = (p.name || '').toLowerCase();
    const blob = [p.name, p.brand, p.category].filter(Boolean).join(' ').toLowerCase();

    if (type) {
      if (name.includes(type)) score += 6;
      else if (blob.includes(type)) score += 3;
    }
    for (const a of attrs) {
      if (blob.includes(a)) score += 2;
    }
    if (p.isEditorsChoice) score += 2;
    if (typeof p.rating === 'number') score += Math.min(p.rating, 5);
    if (p.storeUrl) score += 1;
    if (p.inStock) score += 1;

    return { p, score, index };
  });

  scored.sort((a, b) => (b.score - a.score) || (a.index - b.index));

  return scored.slice(0, limit).map(({ p }) => ({
    id: p.id,
    name: p.name,
    brand: p.brand,
    price: p.price,
    currency: p.currency,
    imageUrl: p.imageUrl,
    rating: p.rating,
    category: p.category,
    storeUrl: p.storeUrl,
    inStock: p.inStock,
  }));
}
