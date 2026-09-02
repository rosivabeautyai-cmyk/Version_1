import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

import { config } from './config.js';

let db = null;
let authAdmin = null;

/**
 * Lazily initialize the Firebase Admin SDK from
 * FIREBASE_SERVICE_ACCOUNT_JSON (same secret shape as
 * scripts/awin-sync). The Admin SDK bypasses Firestore security
 * rules, which is why the backend can read `products` server-side.
 * @return {import('firebase-admin/firestore').Firestore}
 */
export function getDb() {
  if (db) return db;
  if (!config.firebase.serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set.');
  }
  let serviceAccount;
  try {
    serviceAccount = JSON.parse(config.firebase.serviceAccountJson);
  } catch {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.');
  }
  if (getApps().length === 0) {
    initializeApp({ credential: cert(serviceAccount) });
  }
  db = getFirestore();
  return db;
}

/**
 * Firebase Admin Auth — used to verify the caller's Firebase ID token
 * on the admin affiliate endpoints. Shares the same lazily-initialized
 * app as getDb().
 * @return {import('firebase-admin/auth').Auth}
 */
export function getAuthAdmin() {
  if (authAdmin) return authAdmin;
  getDb(); // ensures initializeApp() has run
  authAdmin = getAuth();
  return authAdmin;
}

/** Test seam: inject a fake Firestore. */
export function __setDbForTests(fake) {
  db = fake;
}

/** Test seam: inject a fake Auth. */
export function __setAuthForTests(fake) {
  authAdmin = fake;
}
