import test from 'node:test';
import assert from 'node:assert/strict';

import { getAiConfig, __resetAiConfigCache } from '../src/appConfig.js';
import { runChat } from '../src/routes/aiChat.js';

/** Fake Firestore returning one app_config/ai doc. */
function fakeDb(docData, { throwOnGet = false } = {}) {
  return {
    collection() {
      return {
        doc() {
          return {
            async get() {
              if (throwOnGet) throw new Error('firestore down');
              return {
                exists: docData != null,
                data: () => docData || {},
              };
            },
          };
        },
      };
    },
  };
}

test('getAiConfig: missing doc -> fail-open default (enabled, no maintenance)', async () => {
  __resetAiConfigCache();
  const cfg = await getAiConfig({ _db: fakeDb(null), force: true });
  assert.equal(cfg.enabled, true);
  assert.equal(cfg.maintenanceMode, false);
});

test('getAiConfig: Firestore throws -> fail-open default', async () => {
  __resetAiConfigCache();
  const cfg = await getAiConfig({ _db: fakeDb({}, { throwOnGet: true }), force: true });
  assert.equal(cfg.enabled, true);
  assert.equal(cfg.maintenanceMode, false);
});

test('getAiConfig: reads real fields from the doc', async () => {
  __resetAiConfigCache();
  const cfg = await getAiConfig({
    _db: fakeDb({
      enabled: false,
      maintenanceMode: true,
      maintenanceMessageEn: 'Back soon',
      maintenanceMessageAr: 'هنرجع قريب',
    }),
    force: true,
  });
  assert.equal(cfg.enabled, false);
  assert.equal(cfg.maintenanceMode, true);
  assert.equal(cfg.maintenanceMessageEn, 'Back soon');
  assert.equal(cfg.maintenanceMessageAr, 'هنرجع قريب');
});

test('runChat: maintenanceMode -> 503 ai_maintenance, no Groq/Firestore work, gender women', async () => {
  let intentCalled = false;
  let searchCalled = false;
  const { status, body } = await runChat({
    request: { message: 'I want mascara', history: [], locale: 'en' },
    _getAiConfig: async () => ({
      enabled: true,
      maintenanceMode: true,
      maintenanceMessageEn: 'Under maintenance, back shortly',
      maintenanceMessageAr: '',
    }),
    _extractIntent: async () => {
      intentCalled = true;
      return { intent: {}, llmUsed: false, llmError: null };
    },
    _searchProducts: async () => {
      searchCalled = true;
      return { products: [], stage: 0 };
    },
    _generateProductsIntro: async () => 'unused',
  });
  assert.equal(status, 503);
  assert.equal(body.error, 'ai_maintenance');
  assert.equal(body.reply, 'Under maintenance, back shortly');
  assert.equal(body.intent.gender, 'women');
  assert.deepEqual(body.products, []);
  assert.equal(intentCalled, false, 'intent extraction must be skipped');
  assert.equal(searchCalled, false, 'product search must be skipped');
});

test('runChat: enabled:false -> 503 ai_maintenance (Arabic message for Arabic input)', async () => {
  const { status, body } = await runChat({
    request: { message: 'عايزة ماسكرا', history: [], locale: 'ar' },
    _getAiConfig: async () => ({
      enabled: false,
      maintenanceMode: false,
      maintenanceMessageEn: 'off',
      maintenanceMessageAr: 'المساعد مقفول مؤقتًا',
    }),
    _extractIntent: async () => {
      throw new Error('should not be called');
    },
    _searchProducts: async () => {
      throw new Error('should not be called');
    },
    _generateProductsIntro: async () => 'x',
  });
  assert.equal(status, 503);
  assert.equal(body.error, 'ai_maintenance');
  assert.equal(body.reply, 'المساعد مقفول مؤقتًا');
});

test('runChat: enabled + no maintenance -> proceeds normally (intent seam runs)', async () => {
  let intentCalled = false;
  const { status, body } = await runChat({
    request: { message: "I want men's perfume", history: [], locale: 'en' },
    _getAiConfig: async () => ({
      enabled: true,
      maintenanceMode: false,
      maintenanceMessageEn: '',
      maintenanceMessageAr: '',
    }),
    _extractIntent: async () => {
      intentCalled = true;
      return {
        intent: {
          category: null, productType: null, attributes: [],
          gender: 'women', unsupported: true, reason: 'mens-product',
        },
        llmUsed: false, llmError: null,
      };
    },
    _searchProducts: async () => ({ products: [], stage: 0 }),
    _generateProductsIntro: async () => 'x',
  });
  assert.equal(intentCalled, true);
  assert.equal(status, 200);
  assert.deepEqual(body.products, []);
});
