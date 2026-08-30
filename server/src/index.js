import express from 'express';
import cors from 'cors';

import { config, validateConfig } from './config.js';
import { throttle } from './middleware/throttle.js';
import { aiChatHandler } from './routes/aiChat.js';

const app = express();

app.use(
  cors(
    config.allowedOrigins.length
      ? { origin: config.allowedOrigins }
      : {}, // allow all — fine for a mobile app calling the API directly
  ),
);
app.use(express.json({ limit: '32kb' }));

// Health check (Render pings this).
app.get('/health', (_req, res) => {
  const problems = validateConfig();
  res.status(problems.length ? 503 : 200).json({
    status: problems.length ? 'degraded' : 'ok',
    model: config.groq.model,
    problems,
  });
});

app.post('/api/ai/chat', throttle, aiChatHandler);

// Fallback error handler — never leak internals.
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err?.message || err);
  res.status(500).json({ error: 'internal', reply: null, products: [] });
});

const problems = validateConfig();
if (problems.length) {
  console.warn(
    '[rosiva-ai-backend] starting with configuration problems:\n  - ' +
      problems.join('\n  - ') +
      '\n  /health will report "degraded" and /api/ai/chat will return friendly errors.',
  );
}

app.listen(config.port, () => {
  console.log(`[rosiva-ai-backend] listening on :${config.port} (model: ${config.groq.model})`);
});

export { app };
