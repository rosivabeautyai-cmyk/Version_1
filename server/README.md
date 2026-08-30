# ROSIVA AI Backend

Small Node + Express service that powers the in-app AI beauty assistant.
It replaced direct Gemini / Firebase AI Logic calls from the Flutter app so
that:

- the LLM API key lives **only on the server** (`GROQ_API_KEY`);
- Firestore stays the single source of truth for products;
- ROSIVA's women's-only skincare / makeup / perfume rules are enforced by
  **backend code**, never by the LLM.

## Architecture

```
Flutter  (lib/Feature/ai/data/services/ai_backend_service.dart)
   │  POST /api/ai/chat  { message, history[], locale, country, currency }
   ▼
this service
   ├─ 1. deterministic intent pass         src/intent/normalize.js
   │     (Arabic→English terms, category detection, out-of-scope detection)
   ├─ 2. Groq assist (optional)            src/intent/extractIntent.js + src/groqClient.js
   │     model = GROQ_MODEL, JSON-only, ~200 tokens; degrades to (1) on failure
   ├─ 3. sanitize / clamp intent           src/intent/normalize.js  (sanitizeIntent)
   │     category ∈ {skincare,makeup,perfume} or null; gender forced to "women";
   │     LLM gender / isRosivaProduct / product ids are ignored entirely
   ├─ 4. two-stage Firestore search        src/products/search.js
   │     always: isRosivaProduct==true  +  rosivaCategory==<one allowed cat>
   │              +  post-filter gender=="women"  +  re-check hard filters in code
   │     stage 1: category + free-text term  →  stage 2: category only (never wider)
   ├─ 5. deterministic ranking             src/products/rank.js
   └─ 6. reply text
         · out-of-scope / no results  → localized deterministic copy (no LLM call)
         · products found             → ONE short Groq call for a natural intro
                                        (name/brand/price only; deterministic fallback)
   ▼
{ reply, intent:{category,productType,gender:"women"}, products:[…] }
```

## Endpoints

### `POST /api/ai/chat`

Request:

```jsonc
{
  "message": "عايزة ماسكرا ضد الميه",
  "history": [                       // optional, most recent first-or-last; capped to 20
    { "role": "user", "text": "…" },
    { "role": "assistant", "text": "…" }
  ],
  "locale": "ar",                    // optional tie-breaker for reply language
  "country": "EG",                  // optional, echoed context only
  "currency": "EGP"                 // optional, echoed context only
}
```

Response (`200`):

```jsonc
{
  "reply": "لقيتلك شوية ماسكرا مناسبة ❤️",
  "intent": { "category": "makeup", "productType": "mascara", "gender": "women" },
  "products": [
    { "id": "…", "name": "…", "brand": "…", "price": 9.0, "currency": "USD",
      "imageUrl": "…", "rating": 4.6, "category": "makeup",
      "storeUrl": "…", "inStock": true }
  ]
}
```

Friendly error envelopes (never leak internals):

| Situation | HTTP | body `error` | `reply` |
|---|---|---|---|
| Groq rate-limited / free-tier exhausted | 429 | `rate_limited` | localized "assistant is busy" |
| Groq unreachable / timeout / 5xx (and no deterministic intent) | 503 | `ai_unavailable` | localized "temporarily unavailable" |
| Firestore read failed | 503 | `catalog_unavailable` | localized "temporarily unavailable" |
| too-fast repeat from same client | 429 | `rate_limited` | `null` |
| identical message within ~4 s | 200 | – | cached previous response (`x-rosiva-dedup: 1`) |
| empty / missing `message` | 400 | `message_required` | `null` |

### `GET /health`

`200 {"status":"ok",…}` when configured, `503 {"status":"degraded","problems":[…]}`
otherwise. Render uses this as the health check path.

## Environment variables

Copy `.env.example` to `.env` for local dev (never commit `.env`).

| Var | Required | Notes |
|---|---|---|
| `GROQ_API_KEY` | yes | Server-side only. https://console.groq.com/keys (no card). |
| `GROQ_MODEL` | no | Default `llama-3.3-70b-versatile`. Any current free model — see https://console.groq.com/docs/models |
| `GROQ_FALLBACK_MODEL` | no | Tried once on a 429 for the primary model. Default `llama-3.1-8b-instant`. Blank to disable. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | yes | Full service-account key JSON on one line (same secret shape as `scripts/awin-sync`). Admin SDK bypasses Firestore rules. |
| `PORT` | no | Default `8080`. Render injects this automatically. |
| `ALLOWED_ORIGINS` | no | Comma-separated CORS allow-list. Blank = allow all (fine for the mobile app). |
| `GROQ_TIMEOUT_MS` | no | Default `12000`. |

**Configure the key without a file / without pasting it anywhere shared:**

```powershell
$env:GROQ_API_KEY = "YOUR_KEY"
$env:FIREBASE_SERVICE_ACCOUNT_JSON = (Get-Content path\to\service-account.json -Raw)
npm start
```

## Run locally

```powershell
cd server
npm install
npm run dev          # http://localhost:8080
```

## Tests

```powershell
cd server
npm test             # node --test  (no network, Groq + Firestore are faked)
```

Suites:

- `test/intent.test.js` – the 10 acceptance intents (English + Arabic + mixed),
  follow-up context, deterministic degradation when Groq is down.
- `test/hardFilter.test.js` – the security contract: an LLM response claiming
  `gender:"men"`, `category:"household"`, `isRosivaProduct:false`, or
  fabricated product ids can never escape `isRosivaProduct==true` +
  `gender=="women"` + allowed-category, and products only ever come from
  Firestore.

## Deploy — Render.com (free)

`render.yaml` is a Render blueprint (Docker runtime, `plan: free`,
`healthCheckPath: /health`, `rootDir: server`).

1. Push this repo to GitHub.
2. Render dashboard → **New + → Blueprint** → select the repo.
3. Set the two secrets (`sync:false` in the blueprint, so never in git):
   `GROQ_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON`.
4. Deploy. Render gives you `https://<name>.onrender.com` with HTTPS.
5. Build the app pointing at it:
   `flutter build apk --dart-define=AI_BACKEND_URL=https://<name>.onrender.com`

The `Dockerfile` is provider-agnostic — the same image runs on Fly.io,
Railway, Koyeb, Cloud Run, or `docker run -p 8080:8080 --env-file .env`.

> Free Render instances sleep after ~15 min idle (cold start ~30–50 s). The
> Flutter client uses a 45 s AI timeout and shows a friendly retry message if
> the cold start is slower.

## Rotate the API key

1. Create a new key at https://console.groq.com/keys.
2. Update `GROQ_API_KEY` in the Render dashboard (or your `.env` / shell env).
3. Redeploy / restart the service.
4. Delete the old key in the Groq console.

No Flutter rebuild or app-store release is required — the key never ships in
the client.

## Free-tier / cost protection built in

- request timeout (`GROQ_TIMEOUT_MS`) + 45 s client timeout;
- conversation history capped to 20 messages, each ≤ 500 chars;
- message length capped to 500 chars (truncated, not rejected);
- per-client min request gap + identical-message dedupe (`src/middleware/throttle.js`);
- at most **2** Groq calls per user message (intent + reply), and **0** for
  out-of-scope or no-result answers;
- 429 is never retried against the same model (one fallback-model attempt only);
- transient 5xx / timeout: at most 2 short backed-off retries;
- only name/brand/price of the ≤ 6 ranked candidates is ever sent to Groq —
  never the catalog, descriptions, or ingredients.
