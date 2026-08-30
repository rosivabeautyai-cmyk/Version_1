/**
 * Firestore security-rules unit tests for the ROSIVA Admin upgrade.
 *
 * Proves that the additive admin-write rules do NOT open any hole:
 *  - a normal signed-in user can read the catalog/config but cannot
 *    write products, countries, currencies, or app_config
 *  - an admin can write ONLY the admin-managed product fields (and
 *    can't touch a sync-owned field, hard-delete, or self-promote)
 *  - an admin can toggle another user's `disabled` flag and nothing
 *    else (no role escalation)
 *  - unauthenticated access is denied everywhere it should be
 *
 * Run from the repo root:
 *   (cd test/firestore_rules && npm install)     # once
 *   firebase emulators:exec --only firestore \
 *     "node --test test/firestore_rules/rules.test.mjs"
 */
import { readFileSync } from 'node:fs';
import test from 'node:test';
import assert from 'node:assert/strict';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'rosiva-rules-test',
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  // Seed baseline docs with rules disabled.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/admin1'), { role: 'admin', disabled: false });
    await setDoc(doc(db, 'users/user1'), { role: 'user', disabled: false });
    await setDoc(doc(db, 'users/user2'), { role: 'user', disabled: false });
    await setDoc(doc(db, 'products/p1'), {
      id: 'p1',
      name: 'Awin Name',
      price: 20,
      currency: 'GBP',
      storeUrl: 'https://awin/deep',
      rosivaCategory: 'makeup',
      isRosivaProduct: true,
      gender: 'women',
      featured: false,
      active: true,
    });
    await setDoc(doc(db, 'countries/EG'), { countryCode: 'EG', enabled: true });
    await setDoc(doc(db, 'currencies/EGP'), { code: 'EGP', symbol: 'x' });
    await setDoc(doc(db, 'app_config/ai'), { enabled: true, maintenanceMode: false });
  });
});

test.after(async () => {
  await testEnv?.cleanup();
});

test.beforeEach(async () => {
  // keep seeded docs; only clear between the mutation tests that add rows
});

function asAdmin() {
  return testEnv.authenticatedContext('admin1').firestore();
}
function asUser(uid = 'user1') {
  return testEnv.authenticatedContext(uid).firestore();
}
function asAnon() {
  return testEnv.unauthenticatedContext().firestore();
}

// ---------------------------------------------------------------------
// Reads
// ---------------------------------------------------------------------

test('signed-in user CAN read products / countries / currencies / app_config', async () => {
  const db = asUser();
  await assertSucceeds(getDoc(doc(db, 'products/p1')));
  await assertSucceeds(getDoc(doc(db, 'countries/EG')));
  await assertSucceeds(getDoc(doc(db, 'currencies/EGP')));
  await assertSucceeds(getDoc(doc(db, 'app_config/ai')));
});

test('anonymous CANNOT read products / countries / app_config', async () => {
  const db = asAnon();
  await assertFails(getDoc(doc(db, 'products/p1')));
  await assertFails(getDoc(doc(db, 'countries/EG')));
  await assertFails(getDoc(doc(db, 'app_config/ai')));
});

// ---------------------------------------------------------------------
// Product writes
// ---------------------------------------------------------------------

test('normal user CANNOT write any product field', async () => {
  const db = asUser();
  await assertFails(
    updateDoc(doc(db, 'products/p1'), { featured: true }),
  );
  await assertFails(
    updateDoc(doc(db, 'products/p1'), { price: 1 }),
  );
});

test('admin CAN update admin-managed product fields', async () => {
  const db = asAdmin();
  await assertSucceeds(
    updateDoc(doc(db, 'products/p1'), {
      featured: true,
      active: false,
      productType: 'mascara',
      adminNote: 'checked',
      adminOverrides: { price: 12.99, currency: 'USD' },
      adminUpdatedAt: serverTimestamp(),
      adminUpdatedBy: 'admin1',
    }),
  );
});

test('admin CANNOT touch a sync-owned product field', async () => {
  const db = asAdmin();
  await assertFails(updateDoc(doc(db, 'products/p1'), { price: 5 }));
  await assertFails(updateDoc(doc(db, 'products/p1'), { rosivaCategory: 'perfume' }));
  await assertFails(updateDoc(doc(db, 'products/p1'), { isRosivaProduct: false }));
  await assertFails(updateDoc(doc(db, 'products/p1'), { gender: 'men' }));
  await assertFails(
    updateDoc(doc(db, 'products/p1'), { featured: true, name: 'hacked' }),
  );
});

test('nobody can hard-delete a product', async () => {
  await assertFails(deleteDoc(doc(asAdmin(), 'products/p1')));
  await assertFails(deleteDoc(doc(asUser(), 'products/p1')));
});

test('admin-authored product create must be tagged source == "admin"', async () => {
  const db = asAdmin();
  await assertFails(setDoc(doc(db, 'products/admin_new_1'), { name: 'X' }));
  await assertSucceeds(
    setDoc(doc(db, 'products/admin_new_2'), { name: 'X', source: 'admin' }),
  );
  await assertFails(
    setDoc(doc(asUser(), 'products/user_new'), { name: 'X', source: 'admin' }),
  );
});

// ---------------------------------------------------------------------
// Config writes
// ---------------------------------------------------------------------

test('normal user CANNOT write countries / currencies / app_config', async () => {
  const db = asUser();
  await assertFails(setDoc(doc(db, 'countries/US'), { countryCode: 'US' }));
  await assertFails(updateDoc(doc(db, 'currencies/EGP'), { symbol: 'y' }));
  await assertFails(updateDoc(doc(db, 'app_config/ai'), { enabled: false }));
});

test('admin CAN write countries / currencies / app_config', async () => {
  const db = asAdmin();
  await assertSucceeds(setDoc(doc(db, 'countries/US'), { countryCode: 'US', enabled: true }));
  await assertSucceeds(updateDoc(doc(db, 'currencies/EGP'), { rateToUsd: 0.02 }));
  await assertSucceeds(
    updateDoc(doc(db, 'app_config/ai'), { maintenanceMode: true, updatedBy: 'admin1' }),
  );
});

// ---------------------------------------------------------------------
// User docs / role escalation
// ---------------------------------------------------------------------

test('admin CAN toggle another user\'s disabled flag, and ONLY that', async () => {
  const db = asAdmin();
  await assertSucceeds(updateDoc(doc(db, 'users/user1'), { disabled: true }));
  await assertFails(updateDoc(doc(db, 'users/user1'), { role: 'admin' }));
  await assertFails(
    updateDoc(doc(db, 'users/user1'), { disabled: true, fullName: 'x' }),
  );
});

test('a normal user CANNOT self-promote to admin', async () => {
  const db = asUser();
  await assertFails(updateDoc(doc(db, 'users/user1'), { role: 'admin' }));
});

test('a normal user CANNOT disable another user', async () => {
  const db = asUser('user1');
  await assertFails(updateDoc(doc(db, 'users/user2'), { disabled: true }));
});

test('an admin cannot promote themselves via the disabled-only rule', async () => {
  // affectedKeys hasOnly(['disabled']) blocks it; and the self-update
  // rule pins role unchanged too.
  const db = asAdmin();
  await assertFails(updateDoc(doc(db, 'users/admin1'), { role: 'superadmin' }));
});

// ---------------------------------------------------------------------
// Pass 2 — country offers, activity log, AI usage counters
// ---------------------------------------------------------------------

test('admin CAN write countryOffers + hasCountryOffers on a product', async () => {
  const db = asAdmin();
  await assertSucceeds(
    updateDoc(doc(db, 'products/p1'), {
      countryOffers: { EG: { price: 1500, currency: 'EGP', affiliateUrl: 'https://x', inStock: true } },
      hasCountryOffers: true,
      adminUpdatedAt: serverTimestamp(),
      adminUpdatedBy: 'admin1',
    }),
  );
});

test('normal user still CANNOT write countryOffers', async () => {
  await assertFails(
    updateDoc(doc(asUser(), 'products/p1'), { countryOffers: {}, hasCountryOffers: false }),
  );
});

test('admin still CANNOT touch a sync field alongside countryOffers', async () => {
  await assertFails(
    updateDoc(doc(asAdmin(), 'products/p1'), {
      countryOffers: { US: { price: 1, currency: 'USD' } },
      price: 1,
    }),
  );
});

test('activity_log: admin may append AS themselves at server time', async () => {
  const db = asAdmin();
  await assertSucceeds(
    setDoc(doc(db, 'activity_log/e1'), {
      actorUid: 'admin1',
      action: 'product_updated',
      entityType: 'product',
      entityId: 'p1',
      summary: 'x',
      metadata: {},
      createdAt: serverTimestamp(),
    }),
  );
});

test('activity_log: admin CANNOT forge another actor or back-date', async () => {
  const db = asAdmin();
  await assertFails(
    setDoc(doc(db, 'activity_log/e2'), {
      actorUid: 'someone_else',
      action: 'x', entityType: 'product', createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    setDoc(doc(db, 'activity_log/e3'), {
      actorUid: 'admin1',
      action: 'x', entityType: 'product',
      createdAt: new Date('2000-01-01'),
    }),
  );
});

test('activity_log: normal user cannot create or read', async () => {
  await assertFails(
    setDoc(doc(asUser(), 'activity_log/e4'), {
      actorUid: 'user1', action: 'x', entityType: 'y', createdAt: serverTimestamp(),
    }),
  );
  await assertFails(getDoc(doc(asUser(), 'activity_log/e1')));
});

test('activity_log: nobody can update or delete an entry', async () => {
  await assertFails(updateDoc(doc(asAdmin(), 'activity_log/e1'), { summary: 'edited' }));
  await assertFails(deleteDoc(doc(asAdmin(), 'activity_log/e1')));
});

test('ai_usage / ai_user_usage: admin reads, nobody writes', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'ai_usage/2026-08-30'), { requests: 3 });
    await setDoc(doc(ctx.firestore(), 'ai_user_usage/2026-08-30__u1'), { count: 1 });
  });
  await assertSucceeds(getDoc(doc(asAdmin(), 'ai_usage/2026-08-30')));
  await assertFails(getDoc(doc(asUser(), 'ai_usage/2026-08-30')));
  await assertFails(setDoc(doc(asAdmin(), 'ai_usage/2026-08-30'), { requests: 999 }));
  await assertFails(
    setDoc(doc(asUser(), 'ai_user_usage/2026-08-30__u1'), { count: 999 }),
  );
});
