import test from 'node:test';
import assert from 'node:assert/strict';

import { runChat } from '../src/routes/aiChat.js';
import { getTodayUsage, recordAiRequest, dayId } from '../src/usage.js';

const enabledCfg = {
  enabled: true,
  maintenanceMode: false,
  maintenanceMessageEn: '',
  maintenanceMessageAr: '',
  dailyGlobalLimit: null,
  dailyUserLimit: null,
};

const okIntent = {
  intent: {
    category: null, productType: null, attributes: [],
    gender: 'women', unsupported: true, reason: 'x',
  },
  llmUsed: false,
  llmError: null,
};

test('runChat records a successful request (ok:true) with the user id', async () => {
  const calls = [];
  await runChat({
    request: { message: 'I want mascara', history: [], locale: 'en', userId: 'u1' },
    _getAiConfig: async () => enabledCfg,
    _extractIntent: async () => okIntent,
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async (a) => calls.push(a),
  });
  // wrapper fires the record in a detached promise
  await new Promise((r) => setImmediate(r));
  assert.equal(calls.length, 1);
  assert.equal(calls[0].ok, true);
  assert.equal(calls[0].userId, 'u1');
});

test('runChat records ok:false for a non-200 outcome (maintenance)', async () => {
  const calls = [];
  await runChat({
    request: { message: 'hi', history: [], locale: 'en' },
    _getAiConfig: async () => ({ ...enabledCfg, maintenanceMode: true }),
    _recordAiRequest: async (a) => calls.push(a),
  });
  await new Promise((r) => setImmediate(r));
  assert.equal(calls[0].ok, false);
});

test('runChat: over the daily GLOBAL limit -> 429 rate_limited, no intent/search', async () => {
  let intentCalled = false;
  let searchCalled = false;
  const { status, body } = await runChat({
    request: { message: 'I want mascara', history: [], locale: 'en', userId: 'u1' },
    _getAiConfig: async () => ({ ...enabledCfg, dailyGlobalLimit: 5 }),
    _getTodayUsage: async () => ({ globalRequests: 5, userRequests: 0 }),
    _extractIntent: async () => { intentCalled = true; return okIntent; },
    _searchProducts: async () => { searchCalled = true; return { products: [], stage: 0 }; },
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async () => {},
  });
  assert.equal(status, 429);
  assert.equal(body.error, 'rate_limited');
  assert.equal(body.intent.gender, 'women');
  assert.deepEqual(body.products, []);
  assert.equal(intentCalled, false);
  assert.equal(searchCalled, false);
});

test('runChat: under the global limit -> proceeds', async () => {
  let intentCalled = false;
  await runChat({
    request: { message: 'I want mascara', history: [], locale: 'en' },
    _getAiConfig: async () => ({ ...enabledCfg, dailyGlobalLimit: 100 }),
    _getTodayUsage: async () => ({ globalRequests: 3, userRequests: 0 }),
    _extractIntent: async () => { intentCalled = true; return okIntent; },
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async () => {},
  });
  assert.equal(intentCalled, true);
});

test('runChat: over the per-USER daily limit -> 429', async () => {
  const { status, body } = await runChat({
    request: { message: 'x', history: [], locale: 'en', userId: 'heavy' },
    _getAiConfig: async () => ({ ...enabledCfg, dailyUserLimit: 3 }),
    _getTodayUsage: async () => ({ globalRequests: 0, userRequests: 3 }),
    _extractIntent: async () => { throw new Error('should not run'); },
    _searchProducts: async () => { throw new Error('should not run'); },
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async () => {},
  });
  assert.equal(status, 429);
  assert.equal(body.error, 'rate_limited');
});

test('runChat: per-user limit is skipped when there is no user id', async () => {
  let intentCalled = false;
  await runChat({
    request: { message: 'x', history: [], locale: 'en' }, // no userId
    _getAiConfig: async () => ({ ...enabledCfg, dailyUserLimit: 1 }),
    _getTodayUsage: async () => ({ globalRequests: 0, userRequests: 999 }),
    _extractIntent: async () => { intentCalled = true; return okIntent; },
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async () => {},
  });
  assert.equal(intentCalled, true);
});

test('runChat: no limits configured -> usage counter is NOT read', async () => {
  let usageRead = false;
  await runChat({
    request: { message: 'x', history: [], locale: 'en' },
    _getAiConfig: async () => enabledCfg, // both limits null
    _getTodayUsage: async () => { usageRead = true; return { globalRequests: 0, userRequests: 0 }; },
    _extractIntent: async () => okIntent,
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'x',
    _recordAiRequest: async () => {},
  });
  assert.equal(usageRead, false);
});

test('getTodayUsage: fail-open to zeros when Firestore throws', async () => {
  const badDb = {
    collection() {
      return { doc() { return { async get() { throw new Error('down'); } }; } };
    },
  };
  const u = await getTodayUsage({ userId: 'u', _db: badDb });
  assert.deepEqual(u, { globalRequests: 0, userRequests: 0 });
});

test('recordAiRequest: never throws even if Firestore throws', async () => {
  const badDb = {
    collection() {
      return { doc() { return { set() { throw new Error('down'); } }; } };
    },
  };
  await recordAiRequest({ ok: true, userId: 'u', _db: badDb }); // must resolve
  assert.ok(true);
});

test('dayId is a UTC YYYY-MM-DD string', () => {
  assert.match(dayId(new Date('2026-08-30T23:59:00Z')), /^\d{4}-\d{2}-\d{2}$/);
  assert.equal(dayId(new Date('2026-08-30T23:59:00Z')), '2026-08-30');
});
