import { config } from '../config.js';

/**
 * Minimal in-memory, per-client throttle + duplicate suppression.
 *
 * Free-tier protection, not a security control. "Client" = client IP +
 * optional `x-user-id` header. Two guards:
 *   1. min gap between requests (config.limits.minRequestGapMs)
 *   2. identical message within duplicateWindowMs -> replay the last
 *      response instead of calling Groq again
 *
 * State is process-local and self-evicting; fine for a single small
 * instance (which is all the free tier runs).
 */

const lastRequestAt = new Map(); // key -> ms
const recentResponses = new Map(); // key -> { message, body, at }

function clientKey(req) {
  // Prefer the verified Firebase uid (set by verifyUser). It cannot be
  // spoofed via a forged X-Forwarded-For, unlike the IP fallback.
  if (req.authUser?.uid) return `uid:${req.authUser.uid}`;
  const ip =
    (req.headers['x-forwarded-for'] || '').split(',')[0].trim() ||
    req.socket?.remoteAddress ||
    'unknown';
  const user = String(req.headers['x-user-id'] || '').slice(0, 128);
  return `${ip}|${user}`;
}

function sweep(now) {
  const ttl = Math.max(config.limits.duplicateWindowMs, config.limits.minRequestGapMs) * 4;
  for (const [k, t] of lastRequestAt) if (now - t > ttl) lastRequestAt.delete(k);
  for (const [k, v] of recentResponses) if (now - v.at > config.limits.duplicateWindowMs) recentResponses.delete(k);
}

/**
 * Express middleware. On a duplicate within the window it short-circuits
 * with the cached body. On too-fast repeat it 429s with a friendly-safe
 * JSON (the client maps `error: "rate_limited"` to localized copy).
 */
export function throttle(req, res, next) {
  const now = Date.now();
  sweep(now);
  const key = clientKey(req);
  req._clientKey = key;

  const message = typeof req.body?.message === 'string' ? req.body.message.trim() : '';

  const cached = recentResponses.get(key);
  if (cached && cached.message === message && now - cached.at < config.limits.duplicateWindowMs) {
    res.set('x-rosiva-dedup', '1');
    return res.status(200).json(cached.body);
  }

  const last = lastRequestAt.get(key) || 0;
  if (now - last < config.limits.minRequestGapMs) {
    return res.status(429).json({ error: 'rate_limited', reply: null, products: [] });
  }
  lastRequestAt.set(key, now);
  next();
}

/** Called by the route on a successful response so dedupe can replay it. */
export function rememberResponse(key, message, body) {
  recentResponses.set(key, { message: (message || '').trim(), body, at: Date.now() });
}

/** Test helper. */
export function __resetThrottle() {
  lastRequestAt.clear();
  recentResponses.clear();
}
