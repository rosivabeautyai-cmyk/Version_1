import test from 'node:test';
import assert from 'node:assert/strict';

import { searchProducts, passesHardFilters } from '../src/products/search.js';
import { extractIntent } from '../src/intent/extractIntent.js';
import { runChat } from '../src/routes/aiChat.js';
import { makeFakeFirestore, sampleProducts } from './helpers.js';

test('searchProducts always constrains isRosivaProduct==true AND rosivaCategory, whatever the intent', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  await searchProducts({ category: 'makeup', productType: 'mascara', _db: db });

  const wheres = db.__recordedWheres.filter((w) => w.collection === 'products');
  assert.ok(
    wheres.some((w) => w.field === 'isRosivaProduct' && w.op === '==' && w.value === true),
    'isRosivaProduct == true must be a server-side filter',
  );
  assert.ok(
    wheres.some((w) => w.field === 'rosivaCategory' && w.op === '==' && w.value === 'makeup'),
    'rosivaCategory == <allowed category> must be a server-side filter',
  );
});

test('men\'s and unisex and household rows can never pass the hard filter', () => {
  const bad = sampleProducts
    .filter((p) => ['men1', 'u1', 'h1'].includes(p.id))
    .map((p) => ({
      isRosivaProduct: p.isRosivaProduct === true,
      gender: p.gender,
      category: p.rosivaCategory,
    }));
  for (const p of bad) assert.equal(passesHardFilters(p), false);
});

test('searchProducts returns only eligible women\'s products of the requested category', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const { products } = await searchProducts({ category: 'makeup', productType: 'mascara', _db: db });
  assert.ok(products.length > 0);
  for (const p of products) {
    assert.equal(p.gender, 'women');
    assert.equal(p.isRosivaProduct, true);
    assert.equal(p.category, 'makeup');
  }
  assert.ok(!products.some((p) => p.id === 'men1'));
});

test('Security — LLM says gender:"men": output intent.gender is still "women" and no men\'s product leaks', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const { body } = await runChat({
    request: { message: 'I want a mascara', history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: { category: 'makeup', productType: 'mascara', attributes: [], gender: 'men', unsupported: false, reason: 'x' },
      llmUsed: true,
      llmError: null,
    }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'here you go',
  });
  assert.equal(body.intent.gender, 'women');
  assert.ok(body.products.length > 0);
  assert.ok(!body.products.some((p) => p.id === 'men1'));
});

test('Security — LLM says category:"household": nothing is returned, no household row leaks', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const { body } = await runChat({
    request: { message: 'show me something', history: [], locale: 'en' },
    _extractIntent: async () => ({
      // sanitizeIntent would already have nulled this; simulate a bug
      // where it didn't, to prove the search layer is independent.
      intent: { category: 'household', productType: 'degreaser', attributes: [], gender: 'women', unsupported: false, reason: 'x' },
      llmUsed: true,
      llmError: null,
    }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'x',
  });
  assert.deepEqual(body.products, []);
});

test('Security — LLM says isRosivaProduct:false: query still forces isRosivaProduct==true', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  await runChat({
    request: { message: 'I want perfume', history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: { category: 'perfume', productType: 'perfume', attributes: [], gender: 'women', unsupported: false, reason: 'x' },
      llmUsed: true, llmError: null,
    }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'x',
  });
  assert.ok(
    db.__recordedWheres.some((w) => w.field === 'isRosivaProduct' && w.value === true),
  );
});

test('Security — LLM-supplied product ids are ignored; products come only from Firestore', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const { body } = await runChat({
    request: { message: 'I want perfume', history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: {
        category: 'perfume', productType: 'perfume', attributes: [], gender: 'women',
        unsupported: false, reason: 'x',
        // hallucinated fields that must be ignored entirely:
        products: [{ id: 'FAKE-1', name: 'Totally Real Perfume', price: 999 }],
      },
      llmUsed: true, llmError: null,
    }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'x',
  });
  const firestoreIds = new Set(sampleProducts.map((p) => p.id));
  assert.ok(body.products.length > 0);
  for (const p of body.products) {
    assert.ok(firestoreIds.has(p.id), `product ${p.id} must originate from Firestore`);
  }
  assert.ok(!body.products.some((p) => p.id === 'FAKE-1'));
});

test('Security — an all-at-once adversarial LLM blob still yields only Firestore women\'s products', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  // A single hallucinated JSON object that lies about everything the
  // backend must not trust from the model.
  const adversarial = JSON.stringify({
    category: 'household',
    productType: 'floor cleaner',
    gender: 'men',
    isRosivaProduct: true,
    unsupported: false,
    products: [
      { id: 'HALLUCINATED-1', name: 'Fake Serum', brand: 'Nope', price: 999, gender: 'men' },
      { id: 'men1', name: "Men's Beard Mascara", price: 1 },
    ],
  });

  const { body } = await runChat({
    request: { message: 'I want a nice perfume please', history: [], locale: 'en' },
    _extractIntent: (args) => extractIntent({ ...args, _groq: async () => adversarial }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'here you go',
  });

  // gender is always women; household/floor-cleaner is dropped so the
  // only actionable signal left is the deterministic "perfume".
  assert.equal(body.intent.gender, 'women');
  assert.equal(body.intent.category, 'perfume');
  const firestoreIds = new Set(sampleProducts.map((p) => p.id));
  for (const p of body.products) {
    assert.ok(firestoreIds.has(p.id), `id ${p.id} must come from Firestore`);
    assert.notEqual(p.id, 'HALLUCINATED-1');
    assert.notEqual(p.id, 'men1');
  }
  // and every returned product is an eligible women's perfume
  for (const p of body.products) {
    assert.equal(p.category, 'perfume');
  }
});

test('Security — deterministic layer alone (no Groq) rejects the full out-of-scope list', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const cases = [
    "I want men's perfume", 'عطر رجالي', 'unisex perfume', 'عطر unisex',
    'I want shampoo', 'عايزة شامبو', 'I want deodorant', 'عايزة منتجات للشعر',
    'household products', 'I want a hair dryer',
  ];
  for (const message of cases) {
    const { status, body } = await runChat({
      request: { message, history: [], locale: 'en' },
      // Force "no Groq": the deterministic pass must stand on its own.
      _extractIntent: (args) =>
        extractIntent({
          ...args,
          _groq: async () => {
            const e = new Error('no key');
            e.name = 'GroqError';
            throw e;
          },
        }),
      _searchProducts: (args) => searchProducts({ ...args, _db: db }),
      _generateProductsIntro: async () => 'unused',
    });
    assert.equal(status, 200, `${message} -> should resolve to a friendly 200`);
    assert.deepEqual(body.products, [], `${message} -> no products`);
    assert.equal(body.intent.gender, 'women');
  }
});

test('runChat: unsupported intent -> friendly reply, no products, no throw', async () => {
  const { status, body } = await runChat({
    request: { message: "I want men's perfume", history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: { category: null, productType: null, attributes: [], gender: 'women', unsupported: true, reason: 'mens-product' },
      llmUsed: false, llmError: null,
    }),
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'unused',
  });
  assert.equal(status, 200);
  assert.deepEqual(body.products, []);
  assert.equal(body.intent.gender, 'women');
  assert.match(body.reply, /women|نسائي|روزيفيا/i);
});

test('runChat: empty search results -> deterministic "no products", never fabricated', async () => {
  const { body } = await runChat({
    request: { message: 'I want a green mascara', history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: { category: 'makeup', productType: 'green mascara', attributes: [], gender: 'women', unsupported: false, reason: 'x' },
      llmUsed: true, llmError: null,
    }),
    _searchProducts: async () => ({ products: [], stage: 2 }),
    _generateProductsIntro: async () => 'SHOULD NOT BE CALLED',
  });
  assert.deepEqual(body.products, []);
  assert.notEqual(body.reply, 'SHOULD NOT BE CALLED');
});

test('runChat: two-stage fallback still scoped to the same category', async () => {
  const db = makeFakeFirestore({ products: sampleProducts });
  const { body } = await runChat({
    request: { message: 'I want a holographic mascara', history: [], locale: 'en' },
    _extractIntent: async () => ({
      intent: { category: 'makeup', productType: 'holographic mascara', attributes: [], gender: 'women', unsupported: false, reason: 'x' },
      llmUsed: true, llmError: null,
    }),
    _searchProducts: (args) => searchProducts({ ...args, _db: db }),
    _generateProductsIntro: async () => 'here',
  });
  // No "holographic mascara" exists -> stage 2 returns all women's makeup,
  // but NOTHING from perfume/skincare/men/unisex/household.
  assert.ok(body.products.length > 0);
  for (const p of body.products) assert.equal(p.category, 'makeup');
});
