import test from 'node:test';
import assert from 'node:assert/strict';

import { deterministicIntent, sanitizeIntent, normalizeCategory } from '../src/intent/normalize.js';
import { extractIntent } from '../src/intent/extractIntent.js';
import { fakeGroq, inspectingGroq } from './helpers.js';

/** Run the full intent pipeline with the LLM forced to return nothing
 *  useful, so these assert the DETERMINISTIC guarantee. */
async function detOnly(message, history = []) {
  const { intent } = await extractIntent({
    message,
    history,
    _groq: fakeGroq({}), // empty object -> nothing to merge
  });
  return intent;
}

test('Test 1 — "I want mascara" -> makeup / women', async () => {
  const i = await detOnly('I want mascara');
  assert.equal(i.category, 'makeup');
  assert.equal(i.gender, 'women');
  assert.equal(i.unsupported, false);
});

test('Test 2 — "عايزة ماسكرا" -> makeup / women', async () => {
  const i = await detOnly('عايزة ماسكرا');
  assert.equal(i.category, 'makeup');
  assert.equal(i.gender, 'women');
});

test('Test 3 — "عايزة عطر نسائي" -> perfume / women', async () => {
  const i = await detOnly('عايزة عطر نسائي');
  assert.equal(i.category, 'perfume');
  assert.equal(i.gender, 'women');
  assert.equal(i.productType, 'perfume');
});

test('Test 4 — "عايزة فرش مكياج" -> makeup / makeup brush', async () => {
  const i = await detOnly('عايزة فرش مكياج');
  assert.equal(i.category, 'makeup');
  assert.equal(i.productType, 'makeup brush');
});

test('Test 5 — "عايزة شامبو" -> unsupported', async () => {
  const i = await detOnly('عايزة شامبو');
  assert.equal(i.unsupported, true);
  assert.equal(i.category, null);
});

test('Test 6 — "I want men\'s perfume" -> unsupported (mens)', async () => {
  const i = await detOnly("I want men's perfume");
  assert.equal(i.unsupported, true);
  assert.equal(i.category, null);
  assert.match(i.reason, /mens/);
});

test('Test 7 — "I want unisex perfume" -> unsupported (unisex)', async () => {
  const i = await detOnly('I want unisex perfume');
  assert.equal(i.unsupported, true);
  assert.equal(i.category, null);
  assert.match(i.reason, /unisex/);
});

test('Test 8 — follow-up "Waterproof" keeps mascara context (via history + LLM)', async () => {
  let sawHistory = false;
  const groq = inspectingGroq((args) => {
    const hasMascara = args.messages.some(
      (m) => m.role === 'user' && /ماسكرا|mascara/i.test(m.content),
    );
    sawHistory = hasMascara;
    // What a context-aware model returns for "Waterproof" given the
    // prior "I want mascara" turn.
    return { category: 'makeup', productType: 'mascara', attributes: ['waterproof'], unsupported: false };
  });

  const { intent } = await extractIntent({
    message: 'Waterproof',
    history: [
      { role: 'user', text: 'عايزة ماسكرا' },
      { role: 'assistant', text: 'لقيتلك شوية ماسكرا' },
    ],
    _groq: groq,
  });

  assert.equal(sawHistory, true, 'history turns must be sent to the model');
  assert.equal(intent.category, 'makeup');
  assert.equal(intent.productType, 'mascara');
  assert.ok(intent.attributes.includes('waterproof'));
});

test('hair requests are out of scope ("hair serum", "shampoo", Arabic شعر)', async () => {
  for (const msg of ['I want a hair serum', 'I want shampoo', 'عايزة سيروم للشعر']) {
    const i = await detOnly(msg);
    assert.equal(i.unsupported, true, `${msg} must be unsupported`);
    assert.equal(i.category, null);
  }
});

test('"بلسم شفاه" (lip balm) is skincare, NOT rejected as hair conditioner', async () => {
  const i = await detOnly('عايزة بلسم شفاه');
  assert.equal(i.unsupported, false);
  assert.equal(i.category, 'skincare');
});

// ---- follow-up conversation context (the live-check regression) ----

const mascaraHistoryEn = [
  { role: 'user', text: 'I want mascara' },
  { role: 'assistant', text: 'Here are a few mascaras that may suit you' },
];

test('follow-up "waterproof" WITH mascara history -> makeup/mascara, even when Groq returns nothing useful', async () => {
  // Reproduces the live failure: real Groq returned {category:null,...}
  // for the bare "waterproof". The deterministic history inheritance
  // must still resolve it.
  const uselessGroq = fakeGroq({ category: null, productType: null, attributes: ['waterproof'], unsupported: false });
  const { intent } = await extractIntent({
    message: 'waterproof',
    history: mascaraHistoryEn,
    _groq: uselessGroq,
  });
  assert.equal(intent.category, 'makeup');
  assert.equal(intent.productType, 'mascara');
  assert.equal(intent.gender, 'women');
  assert.equal(intent.unsupported, false);
  assert.ok(intent.attributes.includes('waterproof'));
});

test('follow-up "waterproof" WITH history still resolves even if Groq says unsupported:true', async () => {
  const wrongGroq = fakeGroq({ category: null, productType: null, unsupported: true });
  const { intent } = await extractIntent({
    message: 'waterproof',
    history: mascaraHistoryEn,
    _groq: wrongGroq,
  });
  assert.equal(intent.category, 'makeup');
  assert.equal(intent.productType, 'mascara');
});

test('control: "waterproof" with NO history -> category stays null (no independent waterproof->makeup rule)', async () => {
  const uselessGroq = fakeGroq({ category: null, productType: null, attributes: ['waterproof'], unsupported: false });
  const { intent } = await extractIntent({ message: 'waterproof', history: [], _groq: uselessGroq });
  assert.equal(intent.category, null);
  assert.equal(intent.productType, null);
  assert.equal(intent.unsupported, true);
});

test('Arabic follow-up "ضد الميه" after "عايزة ماسكرا" -> makeup/mascara', async () => {
  const uselessGroq = fakeGroq({ category: null, productType: null, unsupported: false });
  const { intent } = await extractIntent({
    message: 'ضد الميه',
    history: [
      { role: 'user', text: 'عايزة ماسكرا' },
      { role: 'assistant', text: 'لقيتلك شوية ماسكرا' },
    ],
    _groq: uselessGroq,
  });
  assert.equal(intent.category, 'makeup');
  assert.equal(intent.productType, 'mascara');
});

test('budget follow-up "under $15" after "I want a perfume" -> perfume', async () => {
  const uselessGroq = fakeGroq({ category: null, productType: null, unsupported: false });
  const { intent } = await extractIntent({
    message: 'under $15',
    history: [
      { role: 'user', text: 'I want a perfume' },
      { role: 'assistant', text: 'Here are some perfumes' },
    ],
    _groq: uselessGroq,
  });
  assert.equal(intent.category, 'perfume');
});

test('non-refinement follow-up "tell me a joke" is NOT hijacked by mascara history', async () => {
  const offTopicGroq = fakeGroq({ category: null, productType: null, unsupported: true });
  const { intent } = await extractIntent({
    message: 'tell me a joke',
    history: mascaraHistoryEn,
    _groq: offTopicGroq,
  });
  assert.equal(intent.category, null);
  assert.equal(intent.unsupported, true);
});

test('follow-up that is itself a full new product request is NOT overridden by prior context', async () => {
  const groq = fakeGroq({ category: 'perfume', productType: 'perfume', unsupported: false });
  const { intent } = await extractIntent({
    message: 'actually show me a perfume instead',
    history: mascaraHistoryEn,
    _groq: groq,
  });
  assert.equal(intent.category, 'perfume');
});

test('Test 9 — "highlighter" -> makeup', async () => {
  const i = await detOnly('highlighter');
  assert.equal(i.category, 'makeup');
});

test('Test 10 — "skincare routine" -> skincare', async () => {
  const i = await detOnly('skincare routine');
  assert.equal(i.category, 'skincare');
});

test('mixed language "عايزة mascara ضد الميه" -> makeup + waterproof', async () => {
  const i = await detOnly('عايزة mascara ضد الميه');
  assert.equal(i.category, 'makeup');
  assert.ok(i.attributes.includes('waterproof'));
});

test('normalizeCategory mirrors the Flutter contract', () => {
  assert.equal(normalizeCategory('Makeup'), 'makeup');
  assert.equal(normalizeCategory('make-up'), 'makeup');
  assert.equal(normalizeCategory('cosmetics'), 'makeup');
  assert.equal(normalizeCategory('Skin Care'), 'skincare');
  assert.equal(normalizeCategory('fragrance'), 'perfume');
  assert.equal(normalizeCategory('household'), null);
  assert.equal(normalizeCategory('hair'), null);
  assert.equal(normalizeCategory(null), null);
});

test('sanitizeIntent: LLM cannot re-open an unsupported deterministic verdict', () => {
  const det = deterministicIntent('عايزة شامبو'); // unsupported
  const out = sanitizeIntent({ category: 'makeup', productType: 'mascara', unsupported: false }, det);
  assert.equal(out.unsupported, true);
  assert.equal(out.category, null);
});

test('sanitizeIntent: LLM category outside the 3 allowed is dropped', () => {
  const det = deterministicIntent('I want a nice thing'); // no match, not unsupported
  const out = sanitizeIntent({ category: 'household', productType: 'floor cleaner' }, det);
  assert.equal(out.category, null);
  assert.equal(out.gender, 'women');
});

test('extractIntent degrades to deterministic result when Groq throws', async () => {
  const throwingGroq = async () => {
    const e = new Error('boom');
    e.name = 'GroqError';
    e.kind = 'unavailable';
    throw e;
  };
  const { intent, llmUsed } = await extractIntent({ message: 'I want mascara', _groq: throwingGroq });
  assert.equal(llmUsed, false);
  assert.equal(intent.category, 'makeup');
});
