/**
 * verifyAdmin — Express middleware that gates the affiliate admin
 * endpoints.
 *
 * The Flutter Admin app sends the signed-in user's Firebase ID token as
 *   Authorization: Bearer <idToken>
 *
 * We:
 *   1. verify the token with the Firebase Admin SDK (signature, expiry,
 *      audience) — a client cannot forge this,
 *   2. look up `users/{uid}` in Firestore and require `role == 'admin'`
 *      — exactly the same server-side check `firestore.rules` uses.
 *
 * We NEVER trust a body/query/header flag such as `isAdmin: true`.
 *
 * On success `req.admin = { uid, email }`.
 */

import { getDb, getAuthAdmin } from '../firebase.js';

export async function verifyAdmin(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const m = /^Bearer\s+(.+)$/i.exec(header.trim());
    if (!m) {
      return res.status(401).json({ error: 'unauthorized', message: 'Missing bearer token.' });
    }
    const idToken = m[1];

    let decoded;
    try {
      decoded = await getAuthAdmin().verifyIdToken(idToken);
    } catch {
      return res.status(401).json({ error: 'unauthorized', message: 'Invalid or expired session.' });
    }

    const uid = decoded.uid;
    let role = null;

    // A custom claim is the fast path; the Firestore doc is the source
    // of truth the rest of the system already relies on.
    if (decoded.admin === true || decoded.role === 'admin') {
      role = 'admin';
    } else {
      try {
        const snap = await getDb().collection('users').doc(uid).get();
        role = snap.exists ? snap.data().role : null;
      } catch {
        return res.status(503).json({ error: 'unavailable', message: 'Could not verify admin role.' });
      }
    }

    if (role !== 'admin') {
      return res.status(403).json({ error: 'forbidden', message: 'Admin access required.' });
    }

    req.admin = { uid, email: decoded.email || null };
    return next();
  } catch (err) {
    console.error('[verifyAdmin] unexpected error:', err?.message || err);
    return res.status(500).json({ error: 'internal' });
  }
}
