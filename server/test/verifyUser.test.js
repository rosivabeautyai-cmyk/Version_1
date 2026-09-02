import test from 'node:test';
import assert from 'node:assert/strict';

import { verifyUser } from '../src/middleware/verifyUser.js';
import { __setAuthForTests } from '../src/firebase.js';

function mockReq({ auth } = {}) {
  return { headers: { authorization: auth ? `Bearer ${auth}` : undefined } };
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

test('verifyUser: no bearer token -> 401, next() NOT called', async () => {
  const res = mockRes();
  let nexted = false;
  await verifyUser(mockReq({}), res, () => (nexted = true));
  assert.equal(res.statusCode, 401);
  assert.equal(res.payload.error, 'unauthorized');
  assert.equal(nexted, false);
});

test('verifyUser: invalid / expired token -> 401', async () => {
  __setAuthForTests(
    fakeAuth(async () => {
      throw new Error('token expired');
    }),
  );
  const res = mockRes();
  let nexted = false;
  await verifyUser(mockReq({ auth: 'bad' }), res, () => (nexted = true));
  assert.equal(res.statusCode, 401);
  assert.equal(nexted, false);
});

test('verifyUser: valid token -> next(), req.authUser set (no role check)', async () => {
  __setAuthForTests(
    fakeAuth(async () => ({ uid: 'u123', email: 'u@example.com' })),
  );
  const req = mockReq({ auth: 'good' });
  const res = mockRes();
  let nexted = false;
  await verifyUser(req, res, () => (nexted = true));
  assert.equal(nexted, true);
  assert.equal(res.statusCode, null);
  assert.deepEqual(req.authUser, { uid: 'u123', email: 'u@example.com' });
});

test('verifyUser: a plain user token is accepted (no admin requirement)', async () => {
  __setAuthForTests(fakeAuth(async () => ({ uid: 'plain-user' })));
  const req = mockReq({ auth: 'good' });
  const res = mockRes();
  let nexted = false;
  await verifyUser(req, res, () => (nexted = true));
  assert.equal(nexted, true);
  assert.equal(req.authUser.uid, 'plain-user');
  assert.equal(req.authUser.email, null);
});
