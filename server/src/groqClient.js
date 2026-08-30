import { config } from './config.js';

/**
 * Typed error for anything that goes wrong talking to Groq, so the
 * route handler can map it to a friendly, localized user message
 * without leaking provider details.
 */
export class GroqError extends Error {
  /**
   * @param {string} message
   * @param {'rate_limit'|'unavailable'|'timeout'|'network'|'bad_response'|'not_configured'|'auth'} kind
   * @param {number} [retryAfterMs]
   */
  constructor(message, kind, retryAfterMs) {
    super(message);
    this.name = 'GroqError';
    this.kind = kind;
    this.retryAfterMs = retryAfterMs;
  }
}

function parseRetryAfter(headerValue) {
  if (!headerValue) return undefined;
  const seconds = Number(headerValue);
  if (Number.isFinite(seconds)) return Math.min(seconds, 60) * 1000;
  const date = Date.parse(headerValue);
  if (Number.isFinite(date)) return Math.max(0, Math.min(date - Date.now(), 60_000));
  return undefined;
}

/**
 * One raw call to Groq's OpenAI-compatible chat/completions endpoint.
 *
 * @param {object} opts
 * @param {Array<{role:string, content:string}>} opts.messages
 * @param {string} opts.model
 * @param {number} [opts.maxTokens]
 * @param {boolean} [opts.jsonMode]
 * @param {number} [opts.temperature]
 * @param {(fn: Function) => Promise<any>} [opts._fetchImpl]  test seam
 * @return {Promise<string>} the assistant message text
 */
export async function groqChat({
  messages,
  model,
  maxTokens = 512,
  jsonMode = false,
  temperature = 0.3,
  _fetchImpl,
}) {
  if (!config.groq.apiKey) {
    throw new GroqError('GROQ_API_KEY missing', 'not_configured');
  }

  const doFetch = _fetchImpl || fetch;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), config.groq.timeoutMs);

  let res;
  try {
    res = await doFetch(`${config.groq.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.groq.apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
        max_tokens: maxTokens,
        temperature,
        ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
      }),
      signal: controller.signal,
    });
  } catch (err) {
    if (err && err.name === 'AbortError') {
      throw new GroqError('Groq request timed out', 'timeout');
    }
    throw new GroqError(`Groq network error: ${err?.message || err}`, 'network');
  } finally {
    clearTimeout(timer);
  }

  if (res.status === 429) {
    throw new GroqError('Groq rate limit', 'rate_limit', parseRetryAfter(res.headers?.get?.('retry-after')));
  }
  if (res.status === 401 || res.status === 403) {
    throw new GroqError('Groq auth rejected', 'auth');
  }
  if (res.status >= 500) {
    throw new GroqError(`Groq unavailable (${res.status})`, 'unavailable');
  }
  if (!res.ok) {
    throw new GroqError(`Groq error (${res.status})`, 'bad_response');
  }

  let data;
  try {
    data = await res.json();
  } catch {
    throw new GroqError('Groq returned non-JSON', 'bad_response');
  }
  const text = data?.choices?.[0]?.message?.content;
  if (typeof text !== 'string' || !text.trim()) {
    throw new GroqError('Groq returned empty content', 'bad_response');
  }
  return text.trim();
}

/**
 * `groqChat` with bounded retry for transient failures only, plus an
 * automatic one-shot fallback to a cheaper model on rate limit.
 *
 *  - timeout / unavailable (5xx): up to 2 short backed-off retries
 *  - rate_limit (429): NOT retried against the same model; tries
 *    GROQ_FALLBACK_MODEL once if configured, otherwise rethrows so the
 *    caller can show the "busy, try again" message. Respects Retry-After
 *    only as an upper bound on our own wait (we never sleep long here).
 *  - auth / not_configured / bad_response: never retried
 *
 * @param {Parameters<typeof groqChat>[0]} opts  (model optional; defaults to config)
 */
export async function groqChatResilient(opts) {
  const primary = opts.model || config.groq.model;
  const maxTransientAttempts = 3;

  for (let attempt = 1; attempt <= maxTransientAttempts; attempt++) {
    try {
      return await groqChat({ ...opts, model: primary });
    } catch (err) {
      if (!(err instanceof GroqError)) throw err;

      if (err.kind === 'rate_limit') {
        if (config.groq.fallbackModel && config.groq.fallbackModel !== primary) {
          try {
            return await groqChat({ ...opts, model: config.groq.fallbackModel });
          } catch (fallbackErr) {
            throw fallbackErr instanceof GroqError ? fallbackErr : err;
          }
        }
        throw err;
      }

      const transient = err.kind === 'timeout' || err.kind === 'unavailable' || err.kind === 'network';
      if (!transient || attempt === maxTransientAttempts) throw err;
      await new Promise((r) => setTimeout(r, 400 * attempt));
    }
  }
  // Unreachable.
  throw new GroqError('exhausted', 'unavailable');
}

/**
 * Tolerant JSON extraction from a model reply that *should* be a JSON
 * object but might be fenced or have a stray prefix.
 * @param {string} text
 * @return {object|null}
 */
export function parseJsonObject(text) {
  if (typeof text !== 'string') return null;
  let t = text.trim();
  const fence = t.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) t = fence[1].trim();
  const start = t.indexOf('{');
  const end = t.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) return null;
  try {
    return JSON.parse(t.slice(start, end + 1));
  } catch {
    return null;
  }
}
