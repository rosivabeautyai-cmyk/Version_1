/**
 * verifyUser — Express middleware that requires a VALID Firebase ID
 * token on a route, with NO role check (any signed-in ROSIVA user).
 *
 * It gates POST /api/ai/chat. Every call to that endpoint costs real
 * Groq tokens + ~80 Firestore reads, so it must only be drivable by a
 * signed-in app user — not an anonymous script that found the URL.
 *
 * The Flutter app sends the signed-in user's Firebase ID token as
 *   Authorization: Bearer <idToken>
 * which the Firebase Admin SDK verifies (signature, expiry, audience).
 * A client cannot forge this.
 *
 * This gate is deliberately NOT fail-open: a missing or unverifiable
 * token is a hard 401. (The AI on/off + daily-limit switches in
 * app_config/ai are the fail-open layer; identity is not.)
 *
 * On success: req.authUser = { uid, email }.
 */

import { getAuthAdmin } from '../firebase.js';

export async function verifyUser(req, res, next) {
  const deny = (message) =>
    res
      .status(401)
      .json({ error: 'unauthorized', message, reply: null, products: [] });

  try {
    const header = req.headers.authorization || '';
    const m = /^Bearer\s+(.+)$/i.exec(header.trim());
    if (!m) return deny('Sign-in required.');

    let decoded;
    try {
      decoded = await getAuthAdmin().verifyIdToken(m[1]);
    } catch {
      return deny('Invalid or expired session.');
    }

    req.authUser = { uid: decoded.uid, email: decoded.email || null };
    return next();
  } catch (err) {
    console.error('[verifyUser] unexpected error:', err?.message || err);
    return res.status(500).json({ error: 'internal', reply: null, products: [] });
  }
}
