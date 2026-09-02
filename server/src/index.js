import express from 'express';
import cors from 'cors';

import { config, validateConfig } from './config.js';
import { throttle } from './middleware/throttle.js';
import { aiChatHandler } from './routes/aiChat.js';
import { affiliateAdminRouter } from './routes/affiliateAdmin.js';

const app = express();
app.disable('x-powered-by');
app.set('trust proxy', true); // behind a PaaS load balancer / TLS terminator

// CORS. Set ALLOWED_ORIGINS (comma-separated) in production so only the
// ROSIVA web frontend's origin is allowed. When it is empty every
// origin is allowed — acceptable for the mobile app (no Origin header)
// and local development, but you SHOULD set it once the web frontend
// URL is known. Requests with no Origin header (native apps, curl,
// health checks) are always allowed.
const corsOptions = {
  origin: config.allowedOrigins.length ? config.allowedOrigins : true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'x-user-id', 'Authorization'],
  maxAge: 86400,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

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

// Admin-only affiliate store operations (Test Connection / Sync Now).
// Every route inside is gated by verifyAdmin (Firebase ID token +
// server-side role check) — see routes/affiliateAdmin.js.
app.use('/api/admin/affiliate-stores', affiliateAdminRouter);

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

// Bind on 0.0.0.0 explicitly so every PaaS (Fly.io, Koyeb, Railway,
// Render, Cloud Run, plain Docker) can route to it. PORT is provided by
// the platform in production, 8080 locally.
app.listen(config.port, '0.0.0.0', () => {
  console.log(`[rosiva-ai-backend] listening on 0.0.0.0:${config.port} (model: ${config.groq.model})`);
});

export { app };
