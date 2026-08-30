import 'dotenv/config';

/**
 * Centralized, validated runtime configuration.
 *
 * The Groq API key lives ONLY here (from the environment) and is never
 * logged, never returned in a response, and never sent anywhere except
 * the Groq API itself.
 */

function optionalNumber(raw, fallback) {
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

export const config = {
  port: optionalNumber(process.env.PORT, 8080),

  groq: {
    apiKey: process.env.GROQ_API_KEY || '',
    model: process.env.GROQ_MODEL || 'llama-3.3-70b-versatile',
    fallbackModel: process.env.GROQ_FALLBACK_MODEL || '',
    baseUrl: 'https://api.groq.com/openai/v1',
    timeoutMs: optionalNumber(process.env.GROQ_TIMEOUT_MS, 12000),
  },

  firebase: {
    serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '',
  },

  allowedOrigins: (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean),

  // Application-level free-tier protection.
  limits: {
    maxMessageLength: 500,
    maxHistoryMessages: 20,
    // Per client key (ip + optional x-user-id): min gap between requests
    // and a short duplicate-suppression window.
    minRequestGapMs: 1200,
    duplicateWindowMs: 4000,
    // Max product candidates returned to the client.
    maxProducts: 6,
  },
};

/**
 * Fails fast on missing critical secrets, but only for the real server
 * bootstrap — tests import the pure modules directly and never call this.
 * @return {string[]} list of human-readable problems (empty = OK)
 */
export function validateConfig() {
  const problems = [];
  if (!config.groq.apiKey) {
    problems.push('GROQ_API_KEY is not set.');
  }
  if (!config.firebase.serviceAccountJson) {
    problems.push('FIREBASE_SERVICE_ACCOUNT_JSON is not set.');
  } else {
    try {
      JSON.parse(config.firebase.serviceAccountJson);
    } catch {
      problems.push('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.');
    }
  }
  return problems;
}
