/**
 * Firebase Admin SDK bootstrap for the sync scripts. Same service
 * account shape as scripts/awin-sync and the /server backend
 * (FIREBASE_SERVICE_ACCOUNT_JSON). The Admin SDK bypasses Firestore
 * security rules — that is why the sync can write `products` and
 * `affiliateStores` while a normal client cannot.
 */

import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

export function loadServiceAccount(raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set.");
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. Paste the full service account key file contents.",
    );
  }
}

export function initFirebase() {
  if (getApps().length === 0) {
    initializeApp({ credential: cert(loadServiceAccount()) });
  }
  return getFirestore();
}
