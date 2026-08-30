/**
 * Tiny in-memory Firestore stand-in supporting exactly the query
 * shape the AI product search uses:
 *   collection(name).where(f,'==',v).where(...).orderBy(f,'desc').limit(n).get()
 * Records every `where` clause so tests can assert the hard filters
 * were actually applied.
 */
export function makeFakeFirestore(docsByCollection = {}) {
  const recordedWheres = [];

  function collection(name) {
    let rows = (docsByCollection[name] || []).map((d, i) => ({
      id: d.id || `doc_${i}`,
      _data: d,
    }));
    const wheres = [];
    let orderField = null;
    let orderDir = 'asc';
    let lim = Infinity;

    const q = {
      where(field, op, value) {
        wheres.push({ field, op, value });
        recordedWheres.push({ collection: name, field, op, value });
        return q;
      },
      orderBy(field, dir = 'asc') {
        orderField = field;
        orderDir = dir;
        return q;
      },
      limit(n) {
        lim = n;
        return q;
      },
      async get() {
        let out = rows.filter((r) =>
          wheres.every(({ field, op, value }) => {
            if (op === '==') return r._data[field] === value;
            return true;
          }),
        );
        if (orderField) {
          out = [...out].sort((a, b) => {
            const av = a._data[orderField] ?? 0;
            const bv = b._data[orderField] ?? 0;
            return orderDir === 'desc' ? bv - av : av - bv;
          });
        }
        out = out.slice(0, lim);
        return {
          docs: out.map((r) => ({ id: r.id, data: () => r._data })),
        };
      },
    };
    return q;
  }

  return { collection, __recordedWheres: recordedWheres };
}

/** A canned Groq call that returns a fixed JSON string. */
export function fakeGroq(jsonObjOrString) {
  return async () =>
    typeof jsonObjOrString === 'string'
      ? jsonObjOrString
      : JSON.stringify(jsonObjOrString);
}

/** A Groq call that inspects the messages it receives. */
export function inspectingGroq(fn) {
  return async (args) => {
    const result = fn(args);
    return typeof result === 'string' ? result : JSON.stringify(result);
  };
}

export const sampleProducts = [
  // eligible women's makeup
  { id: 'm1', name: 'Volume Mascara Waterproof', brand: 'W7', price: 9, currency: 'USD', rating: 4.6, rosivaCategory: 'makeup', isRosivaProduct: true, gender: 'women', storeUrl: 'https://x/1', inStock: true, tags: ['mascara', 'waterproof'] },
  { id: 'm2', name: 'Matte Lipstick Ruby', brand: 'NYX', price: 12, currency: 'USD', rating: 4.4, rosivaCategory: 'makeup', isRosivaProduct: true, gender: 'women', storeUrl: 'https://x/2', inStock: true, tags: ['lipstick'] },
  { id: 'm3', name: 'Pro Makeup Brush Set', brand: 'Real', price: 20, currency: 'USD', rating: 4.8, rosivaCategory: 'makeup', isRosivaProduct: true, gender: 'women', storeUrl: 'https://x/3', inStock: true, tags: ['makeup brush', 'brush'] },
  // men's makeup — must never surface
  { id: 'men1', name: "Men's Beard Filler Mascara", brand: 'X', price: 15, currency: 'USD', rating: 4.9, rosivaCategory: 'makeup', isRosivaProduct: false, gender: 'men', storeUrl: 'https://x/m1', inStock: true, tags: ['mascara'] },
  // unisex perfume — must never surface
  { id: 'u1', name: 'Unisex Oud Eau de Parfum', brand: 'Y', price: 60, currency: 'USD', rating: 5.0, rosivaCategory: 'perfume', isRosivaProduct: false, gender: 'unisex', storeUrl: 'https://x/u1', inStock: true, tags: ['perfume'] },
  // household mislabeled — not an allowed category & not rosiva
  { id: 'h1', name: 'Kitchen Degreaser Spray', brand: 'Z', price: 3, currency: 'USD', rating: 4.0, rosivaCategory: 'household', isRosivaProduct: false, gender: 'unknown', inStock: true, tags: [] },
  // eligible women's perfume
  { id: 'p1', name: 'Rose Blossom Eau de Parfum', brand: 'Zara', price: 30, currency: 'USD', rating: 4.3, rosivaCategory: 'perfume', isRosivaProduct: true, gender: 'women', storeUrl: 'https://x/p1', inStock: true, tags: ['perfume', 'floral'] },
  // eligible women's skincare
  { id: 's1', name: 'Hydrating Face Serum', brand: 'The Ordinary', price: 8, currency: 'USD', rating: 4.7, rosivaCategory: 'skincare', isRosivaProduct: true, gender: 'women', storeUrl: 'https://x/s1', inStock: true, tags: ['serum', 'face serum'] },
];
