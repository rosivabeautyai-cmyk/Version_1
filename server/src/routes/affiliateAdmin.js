/**
 * Admin-only affiliate endpoints.
 *
 *   POST /api/admin/affiliate-stores/:id/test-connection
 *        body (optional): { storeOverride: {...} }  test unsaved config
 *        -> { ok, productsDetected, sampleCount, sample[], validation, error? }
 *
 *   POST /api/admin/affiliate-stores/:id/sync
 *        body (optional): { mode: "auto" | "inline" | "queue" }
 *        - "queue"  : always enqueue an affiliateSyncJobs doc (default for large / unknown)
 *        - "inline" : run a bounded sync now and return the result
 *        - "auto"   : inline for mock/manual/rest small; queue for feeds
 *        -> { mode: "inline", log } | { mode: "queued", jobId }
 *
 * Every private credential stays in the backend environment. Responses
 * never contain secrets (the connector framework redacts + returns safe
 * error shapes).
 */

import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';

import { verifyAdmin } from '../middleware/verifyAdmin.js';
import { getDb } from '../firebase.js';
import { testAffiliateStoreConnection } from '../affiliate/testConnection.mjs';
import { syncAffiliateStore } from '../affiliate/syncEngine.mjs';
import { COLLECTIONS, INTEGRATION_TYPES } from '../affiliate/lib/constants.mjs';

const router = express.Router();

router.use(express.json({ limit: '64kb' }));
router.use(verifyAdmin);

function safe(res, status, payload) {
  return res.status(status).json(payload);
}

router.post('/:id/test-connection', async (req, res) => {
  const storeId = String(req.params.id || '').slice(0, 200);
  if (!storeId) return safe(res, 400, { error: 'bad_request', message: 'store id required' });

  const storeOverride =
    req.body && typeof req.body.storeOverride === 'object' && req.body.storeOverride
      ? { id: storeId, ...req.body.storeOverride }
      : undefined;

  try {
    const result = await testAffiliateStoreConnection({
      db: getDb(),
      storeId,
      storeOverride,
      env: process.env,
    });
    return safe(res, 200, result);
  } catch (err) {
    console.error('[affiliateAdmin] test-connection error:', err?.message || err);
    return safe(res, 200, {
      ok: false,
      error: { code: 'unknown', userMessage: 'The test failed. Check the store configuration.', technical: '' },
    });
  }
});

router.post('/:id/sync', async (req, res) => {
  const storeId = String(req.params.id || '').slice(0, 200);
  if (!storeId) return safe(res, 400, { error: 'bad_request', message: 'store id required' });

  const db = getDb();
  const snap = await db.collection(COLLECTIONS.STORES).doc(storeId).get();
  if (!snap.exists) return safe(res, 404, { error: 'not_found', message: 'store not found' });
  const store = { id: storeId, ...snap.data() };

  const mode = ['auto', 'inline', 'queue'].includes(req.body?.mode) ? req.body.mode : 'auto';

  const inlineEligible =
    store.integrationType === INTEGRATION_TYPES.REST_API ||
    store.integrationType === 'mock' ||
    store.connectorOverride === 'mock';

  const runInline = mode === 'inline' || (mode === 'auto' && inlineEligible);

  if (!runInline) {
    // Enqueue — the GitHub Actions worker (affiliate-sync.yml) drains
    // affiliateSyncJobs and runs the full sync out of band.
    const jobRef = db.collection(COLLECTIONS.SYNC_JOBS).doc();
    await jobRef.set({
      id: jobRef.id,
      storeId,
      status: 'queued',
      mode: 'queue',
      requestedBy: req.admin.uid,
      requestedAt: new Date().toISOString(),
    });
    await db.collection(COLLECTIONS.STORES).doc(storeId).set(
      { syncStatus: 'queued', updatedAt: new Date().toISOString() },
      { merge: true },
    );
    return safe(res, 202, {
      mode: 'queued',
      jobId: jobRef.id,
      message: 'Sync queued. Large feeds are processed by the scheduled worker; check Sync History.',
    });
  }

  try {
    const log = await syncAffiliateStore({
      db,
      storeId,
      triggeredBy: 'admin',
      env: process.env,
      force: true,
      overallTimeoutMs: 60 * 1000, // inline runs are bounded
      fieldValue: FieldValue,
    });
    return safe(res, 200, { mode: 'inline', log });
  } catch (err) {
    console.error('[affiliateAdmin] inline sync error:', err?.message || err);
    return safe(res, 500, { error: 'sync_failed', message: 'Sync failed. Check Sync History.' });
  }
});

export { router as affiliateAdminRouter };
