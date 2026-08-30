import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

import { config } from './config.js';

let db = null;

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

/** Test seam: inject a fake Firestore. */
export function __setDbForTests(fake) {
  db = fake;
}
