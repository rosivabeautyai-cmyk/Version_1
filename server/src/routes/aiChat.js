import { config } from '../config.js';
import { detectDominantLanguage } from '../util/lang.js';
import { extractIntent } from '../intent/extractIntent.js';
import { searchProducts } from '../products/search.js';
import { rankProducts } from '../products/rank.js';
import { deterministicReply, generateProductsIntro, copyFor } from '../reply/generateReply.js';
import { rememberResponse } from '../middleware/throttle.js';
import { getAiConfig } from '../appConfig.js';
import { recordAiRequest, getTodayUsage } from '../usage.js';

/**
 * Validate + clamp the request body. Returns `{ ok, value, error }`.
 */
export function parseChatRequest(body) {
  const b = body && typeof body === 'object' ? body : {};
  const message = typeof b.message === 'string' ? b.message.trim() : '';
  if (!message) return { ok: false, error: 'message_required' };
  if (message.length > config.limits.maxMessageLength) {
    // Truncate rather than reject — better UX, still bounds token cost.
    return {
      ok: true,
      value: {
        message: message.slice(0, config.limits.maxMessageLength),
        history: clampHistory(b.history),
        locale: normalizeLocale(b.locale),
        country: typeof b.country === 'string' ? b.country.slice(0, 64) : null,
        currency: typeof b.currency === 'string' ? b.currency.slice(0, 8) : null,
      },
    };
  }
  return {
    ok: true,
    value: {
      message,
      history: clampHistory(b.history),
      locale: normalizeLocale(b.locale),
      country: typeof b.country === 'string' ? b.country.slice(0, 64) : null,
      currency: typeof b.currency === 'string' ? b.currency.slice(0, 8) : null,
    },
  };
}

function normalizeLocale(raw) {
  const s = String(raw || '').toLowerCase();
  if (s.startsWith('ar')) return 'ar';
  if (s.startsWith('en')) return 'en';
  return '';
}

function clampHistory(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((m) => m && typeof m.text === 'string' && m.text.trim())
    .map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      text: m.text.slice(0, 500),
    }))
    .slice(-config.limits.maxHistoryMessages);
}

/**
 * Public entry: runs the chat pipeline, then best-effort records the
 * outcome in the daily AI usage counters (item 11). The wrapper never
 * lets a metrics failure affect the response. All product/intent/
 * hard-filter logic is untouched inside `_runChatInner`.
 *
 * @param {object} opts
 * @param {object} opts.request  already parsed/clamped (parseChatRequest .value; may carry `userId`)
 * @param {Function} [opts._extractIntent] test seam
 * @param {Function} [opts._searchProducts] test seam
 * @param {Function} [opts._generateProductsIntro] test seam
 * @param {Function} [opts._getAiConfig] test seam
 * @param {Function} [opts._getTodayUsage] test seam
 * @param {Function} [opts._recordAiRequest] test seam
 */
export async function runChat(opts) {
  const {
    request,
    _recordAiRequest = recordAiRequest,
    ...inner
  } = opts;
  const result = await _runChatInner({ request, ...inner });
  // "successful" = a normal 200 answer; anything else counts as failed.
  Promise.resolve(
    _recordAiRequest({ ok: result.status === 200, userId: request?.userId }),
  ).catch(() => {});
  return result;
}

async function _runChatInner({
  request,
  _extractIntent = extractIntent,
  _searchProducts = searchProducts,
  _generateProductsIntro = generateProductsIntro,
  _getAiConfig = getAiConfig,
  _getTodayUsage = getTodayUsage,
}) {
  const { message, history, locale, userId } = request;
  const lang = detectDominantLanguage(message, locale);

  // 0. Admin kill-switch / maintenance mode (app_config/ai). Checked
  //    BEFORE any Groq or Firestore-search work so a disabled or
  //    under-maintenance assistant costs nothing. Fail-open: a config
  //    read error leaves the assistant enabled.
  const aiCfg = await _getAiConfig();
  if (!aiCfg.enabled || aiCfg.maintenanceMode) {
    const c = copyFor(lang);
    const custom = (
      lang === 'ar' ? aiCfg.maintenanceMessageAr : aiCfg.maintenanceMessageEn
    );
    return {
      status: 503,
      body: {
        error: 'ai_maintenance',
        reply: (typeof custom === 'string' && custom.trim()) || c.aiUnavailable,
        intent: { category: null, productType: null, gender: 'women' },
        products: [],
      },
    };
  }

  // 0b. Admin-configured daily request limits (item 12). null =
  //     unlimited. Global limit is a real cap; the per-user limit uses
  //     the advisory request user id and is skipped when absent.
  //     Fail-open: a counter read error does not block the request.
  if (aiCfg.dailyGlobalLimit != null || aiCfg.dailyUserLimit != null) {
    const usage = await _getTodayUsage({ userId });
    const overGlobal =
      aiCfg.dailyGlobalLimit != null &&
      usage.globalRequests >= aiCfg.dailyGlobalLimit;
    const overUser =
      aiCfg.dailyUserLimit != null &&
      userId &&
      usage.userRequests >= aiCfg.dailyUserLimit;
    if (overGlobal || overUser) {
      const c = copyFor(lang);
      return {
        status: 429,
        body: {
          error: 'rate_limited',
          reply: c.aiBusy,
          intent: { category: null, productType: null, gender: 'women' },
          products: [],
        },
      };
    }
  }

  // 1. Intent (deterministic + optional Groq assist).
  let intentResult;
  try {
    intentResult = await _extractIntent({
      message,
      history,
      maxHistory: config.limits.maxHistoryMessages,
    });
  } catch (err) {
    const kind = err?.groqKind;
    const c = copyFor(lang);
    return {
      status: kind === 'rate_limit' ? 429 : 503,
      body: {
        error: kind === 'rate_limit' ? 'rate_limited' : 'ai_unavailable',
        reply: kind === 'rate_limit' ? c.aiBusy : c.aiUnavailable,
        intent: { category: null, productType: null, gender: 'women' },
        products: [],
      },
    };
  }

  const intent = intentResult.intent;
  const publicIntent = {
    category: intent.category,
    productType: intent.productType,
    gender: 'women', // ALWAYS backend-imposed, never from the LLM
  };

  // 2. Out-of-scope request -> deterministic, no product search, no 2nd LLM call.
  if (intent.unsupported || (!intent.category && !intent.productType)) {
    return {
      status: 200,
      body: {
        reply: deterministicReply({ lang, kind: 'unsupported', reason: intent.reason || '' }),
        intent: publicIntent,
        products: [],
      },
    };
  }

  // 3. Two-stage Firestore search with hard filters.
  let search;
  try {
    search = await _searchProducts({
      category: intent.category,
      productType: intent.productType,
      attributes: intent.attributes,
      rawMessage: message,
    });
  } catch (err) {
    const c = copyFor(lang);
    return {
      status: 503,
      body: {
        error: 'catalog_unavailable',
        reply: c.aiUnavailable,
        intent: publicIntent,
        products: [],
      },
    };
  }

  const ranked = rankProducts(search.products, {
    productType: intent.productType,
    attributes: intent.attributes,
    limit: config.limits.maxProducts,
  });

  // 4. Empty results -> deterministic "no products", never fabricate.
  if (ranked.length === 0) {
    return {
      status: 200,
      body: {
        reply: deterministicReply({ lang, kind: 'no_products' }),
        intent: publicIntent,
        products: [],
      },
    };
  }

  // 5. Real products -> one short LLM call for a natural intro
  //    (deterministic fallback baked in).
  const reply = await _generateProductsIntro({ message, lang, products: ranked });

  return {
    status: 200,
    body: { reply, intent: publicIntent, products: ranked },
  };
}

/**
 * Express handler. Assumes `throttle` middleware ran first.
 */
export async function aiChatHandler(req, res) {
  const parsed = parseChatRequest(req.body);
  if (!parsed.ok) {
    return res.status(400).json({ error: parsed.error, reply: null, products: [] });
  }

  // Identity is the VERIFIED Firebase uid (the verifyUser middleware ran
  // before this handler). Used for the per-user daily limit and usage
  // counters — no longer the spoofable `x-user-id` header.
  const userId = req.authUser?.uid || undefined;

  const { status, body } = await runChat({
    request: { ...parsed.value, userId },
  });

  if (status === 200 && req._clientKey) {
    rememberResponse(req._clientKey, parsed.value.message, body);
  }
  return res.status(status).json(body);
}
