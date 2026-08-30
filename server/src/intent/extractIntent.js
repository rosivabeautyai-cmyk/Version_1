import { groqChatResilient, parseJsonObject, GroqError } from '../groqClient.js';
import {
  deterministicIntent,
  sanitizeIntent,
  derivePriorIntent,
  isRefinementFollowUp,
} from './normalize.js';

/**
 * Bounded system prompt for intent extraction. Deliberately tiny —
 * every extra token is spent on every request against a free-tier
 * budget. The model's ONLY job here is to turn natural language
 * (Arabic / English / mixed) into a rough structured guess; the
 * backend re-checks and overrides everything it returns.
 */
const INTENT_SYSTEM_PROMPT = [
  'You extract shopping intent for ROSIVA, a women-only beauty shop that sells',
  'ONLY skincare, makeup, and perfume. Reply with a single minified JSON object,',
  'no prose, no code fence. Schema:',
  '{"category": "skincare"|"makeup"|"perfume"|null,',
  '"productType": string|null,  // short English noun e.g. "mascara", "face serum", "makeup brush"',
  '"attributes": string[],      // English descriptors e.g. ["waterproof"]',
  '"unsupported": boolean}       // true if the request is NOT women\'s skincare/makeup/perfume',
  'Rules: translate Arabic to English for category/productType/attributes (the',
  'catalog is English). If the user asks for men\'s, unisex, hair, body/personal',
  'care, household or anything outside women\'s skincare/makeup/perfume, set',
  'unsupported=true and category=null. The final user message may be only a',
  'refinement of an earlier one (just an attribute like "waterproof", a budget,',
  'a colour, "a cheaper one"): in that case reuse the earlier category and',
  'productType from the conversation. Never invent products. Output JSON only.',
].join(' ');

/**
 * @param {Array<{role:'user'|'assistant', text:string}>} history
 * @param {number} maxTurns
 * @return {Array<{role:string, content:string}>}
 */
function historyToMessages(history, maxTurns) {
  const turns = Array.isArray(history) ? history.slice(-maxTurns) : [];
  return turns
    .filter((m) => m && typeof m.text === 'string' && m.text.trim())
    .map((m) => ({
      role: m.role === 'assistant' ? 'assistant' : 'user',
      content: m.text.slice(0, 500),
    }));
}

/**
 * Full intent pipeline: deterministic pass -> (optional) Groq assist ->
 * sanitize/clamp. Never throws for a Groq failure — it degrades to the
 * deterministic result, which is correct for the common cases.
 *
 * @param {object} opts
 * @param {string} opts.message
 * @param {Array} [opts.history]
 * @param {number} [opts.maxHistory]
 * @param {Function} [opts._groq]  test seam: (args) => Promise<string>
 * @returns {Promise<{intent: object, llmUsed: boolean, llmError: string|null}>}
 */
export async function extractIntent({ message, history = [], maxHistory = 20, _groq }) {
  const det = deterministicIntent(message);

  // Short-circuit: deterministic pass already fully decided an
  // out-of-scope request — no need to spend an LLM call on it.
  if (det.unsupported) {
    return { intent: sanitizeIntent(null, det), llmUsed: false, llmError: null };
  }

  // Most recent categorized request in the conversation — used only so
  // a bare follow-up ("waterproof") can inherit its category.
  const prior = derivePriorIntent(
    Array.isArray(history) ? history.slice(-maxHistory) : [],
  );
  // Can we still answer if Groq is down? Yes when the deterministic
  // pass found a product, OR the message is a refinement of a known
  // prior request.
  const canResolveWithoutLlm =
    !!det.category || !!det.productType || (!!prior && isRefinementFollowUp(message, det));

  const call = _groq || groqChatResilient;
  let llm = null;
  let llmError = null;
  let llmUsed = false;

  try {
    // Give the model an explicit context line too (belt-and-braces
    // alongside the raw history turns) so it resolves follow-ups on
    // its own; the deterministic inheritance below is the guarantee.
    const userContent = prior
      ? `${String(message).slice(0, 500)}\n\n(Conversation context: the user's earlier request was category=${prior.category}` +
        `${prior.productType ? `, productType=${prior.productType}` : ''}. If the message above is only a refinement of that, keep that category and productType.)`
      : String(message).slice(0, 500);

    const raw = await call({
      messages: [
        { role: 'system', content: INTENT_SYSTEM_PROMPT },
        ...historyToMessages(history, maxHistory),
        { role: 'user', content: userContent },
      ],
      maxTokens: 200,
      jsonMode: true,
      temperature: 0,
    });
    llm = parseJsonObject(raw);
    llmUsed = true;
  } catch (err) {
    llmError = err instanceof GroqError ? err.kind : 'unknown';
    // If we can't answer deterministically and the model is
    // unavailable, surface the error so the caller shows "AI busy".
    if (!canResolveWithoutLlm && (llmError === 'rate_limit' || llmError === 'auth' || llmError === 'not_configured')) {
      const e = new Error('intent unavailable');
      e.groqKind = llmError;
      throw e;
    }
  }

  return { intent: sanitizeIntent(llm, det, prior, message), llmUsed, llmError };
}
