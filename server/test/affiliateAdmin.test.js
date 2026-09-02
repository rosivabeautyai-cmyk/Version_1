import test from 'node:test';
import assert from 'node:assert/strict';

import { verifyAdmin } from '../src/middleware/verifyAdmin.js';
import { __setAuthForTests, __setDbForTests } from '../src/firebase.js';

// The vendored affiliate framework (kept in sync by scripts/sync-vendor.mjs).
import { syncAffiliateStore } from '../src/affiliate/syncEngine.mjs';
import { testAffiliateStoreConnection } from '../src/affiliate/testConnection.mjs';
import { MockConnector } from '../src/affiliate/connectors/MockConnector.mjs';
import { COLLECTIONS } from '../src/affiliate/lib/constants.mjs';

/** Minimal Express-ish req/res doubles. */
function mockReq({ auth, params = {}, body = {} } = {}) {
  return {
    headers: { authorization: auth ? `Bearer ${auth}` : undefined },
    params,
    body,
  };
}
function mockRes() {
  return {
    statusCode: null,
    payload: null,
    status(c) {
      this.statusCode = c;
      return this;
    },
    json(p) {
      this.payload = p;
      return this;
    },
  };
}
const fakeAuth = (impl) => ({ verifyIdToken: impl });
const fakeDbWithUser = (uid, role) => ({
  collection: () => ({
    doc: () => ({ get: async () => ({ exists: role != null, data: () => ({ role }) }) }),
  }),
});

test('verifyAdmin: no bearer token -> 401', async () => {
  const res = mockRes();
  let nexted = false;
  await verifyAdmin(mockReq({}), res, () => (nexted = true));
  assert.equal(res.statusCode, 401);
  assert.equal(nexted, false);
});

test('verifyAdmin: invalid token -> 401', async () => {
  __setAuthForTests(fakeAuth(async () => { throw new Error('bad token'); }));
  const res = mockRes();
  await verifyAdmin(mockReq({ auth: 'x' }), res, () => {});
  assert.equal(res.statusCode, 401);
});

test('verifyAdmin: valid token but role != admin -> 403', async () => {
  __setAuthForTests(fakeAuth(async () => ({ uid: 'u1', email: 'u@x.com' })));
  __setDbForTests(fakeDbWithUser('u1', 'user'));
  const res = mockRes();
  let nexted = false;
  await verifyAdmin(mockReq({ auth: 'good' }), res, () => (nexted = true));
  assert.equal(res.statusCode, 403);
  assert.equal(nexted, false);
});

test('verifyAdmin: valid admin token -> next(), req.admin set', async () => {
  __setAuthForTests(fakeAuth(async () => ({ uid: 'admin1', email: 'a@x.com' })));
  __setDbForTests(fakeDbWithUser('admin1', 'admin'));
  const req = mockReq({ auth: 'good' });
  const res = mockRes();
  let nexted = false;
  await verifyAdmin(req, res, () => (nexted = true));
  assert.equal(nexted, true);
  assert.equal(req.admin.uid, 'admin1');
});

test('verifyAdmin: admin custom claim alone is enough (no Firestore lookup)', async () => {
  __setAuthForTests(fakeAuth(async () => ({ uid: 'admin2', admin: true })));
  __setDbForTests({ collection: () => { throw new Error('should not read users'); } });
  const req = mockReq({ auth: 'good' });
  const res = mockRes();
  let nexted = false;
  await verifyAdmin(req, res, () => (nexted = true));
  assert.equal(nexted, true);
});

// --- Vendored framework smoke test (proves server/src/affiliate works) ---

class FakeFs {
  constructor(seed = {}) {
    this.data = new Map(Object.entries(seed).map(([k, v]) => [k, new Map(Object.entries(v))]));
    this._auto = 0;
  }
  _c(n) { if (!this.data.has(n)) this.data.set(n, new Map()); return this.data.get(n); }
  collection(n) {
    const self = this;
    const filters = [];
    const api = {
      doc(id) {
        const rid = id || `a${++self._auto}`;
        return {
          id: rid,
          async get() { const m = self._c(n); return { exists: m.has(rid), id: rid, ref: this, data: () => (m.has(rid) ? { ...m.get(rid) } : undefined) }; },
          async set(d, o = {}) { const m = self._c(n); m.set(rid, o.merge && m.has(rid) ? { ...m.get(rid), ...d } : { ...d }); },
          async update(d) { const m = self._c(n); m.set(rid, { ...m.get(rid), ...d }); },
        };
      },
      where(f, _op, v) { filters.push([f, v]); return api; },
      async get() {
        const m = self._c(n);
        let e = [...m.entries()];
        for (const [f, v] of filters) e = e.filter(([, d]) => d[f] === v);
        return { empty: e.length === 0, size: e.length, docs: e.map(([id, d]) => ({ id, ref: api.doc(id), data: () => ({ ...d }) })) };
      },
    };
    return api;
  }
  batch() {
    const ops = [];
    return {
      set(ref, d, o) { ops.push(() => ref.set(d, o)); return this; },
      update(ref, d) { ops.push(() => ref.update(d)); return this; },
      async commit() { for (const op of ops) await op(); },
    };
  }
}

test('vendored syncEngine + MockConnector: end-to-end upsert', async () => {
  const db = new FakeFs({
    [COLLECTIONS.STORES]: {
      s1: { name: 'M', slug: 'm', currency: 'USD', integrationType: 'mock', status: 'active', syncEnabled: true, syncFrequency: 'daily', defaultCommissionRate: 8 },
    },
  });
  const log = await syncAffiliateStore({
    db,
    storeId: 's1',
    connector: new MockConnector({ id: 's1', slug: 'm', currency: 'USD' }),
    clock: () => '2026-03-01T00:00:00.000Z',
  });
  assert.equal(log.status, 'success');
  assert.equal(log.newProducts, 8);
  assert.equal(db._c(COLLECTIONS.PRODUCTS).size, 8);

  const conn = await testAffiliateStoreConnection({
    db,
    storeId: 's1',
    connector: new MockConnector({ id: 's1', slug: 'm', currency: 'USD' }),
  });
  assert.equal(conn.ok, true);
  assert.ok(conn.sample.length > 0);
});
