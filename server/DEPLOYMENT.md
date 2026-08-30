# ROSIVA AI backend — production deployment

The backend is a plain Node 20 + Express service. It needs: outbound
HTTPS (to Groq + Firestore), an injected `PORT`, and a few environment
variables. It is stateless except for small in-memory throttle caches,
so any single instance is fine.

**Nothing here deploys anything — these are the files/steps to do it.**

---

## Required environment variables

| Var | Required | Notes |
|-----|----------|-------|
| `GROQ_API_KEY` | **yes** | Server-side only. Never in Flutter. |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **yes** | The *entire* service-account JSON, as one string. Server-side only. Never commit `serviceAccount.json`. |
| `GROQ_MODEL` | no | Default `llama-3.3-70b-versatile` (verified by live-check). |
| `GROQ_FALLBACK_MODEL` | no | e.g. `llama-3.1-8b-instant`. |
| `GROQ_TIMEOUT_MS` | no | Default `12000`. |
| `ALLOWED_ORIGINS` | **prod: yes** | Comma-separated list of the web frontend origin(s), e.g. `https://rosiva.web.app,https://rosiva-24fa4.web.app`. Empty ⇒ all origins allowed (OK for the mobile app / local dev, not for a public web build). |
| `PORT` | injected | Set automatically by every PaaS. Locally defaults to `8080`. |

The server binds `0.0.0.0:$PORT`. `GET /health` returns `200 {"status":"ok"}`
when both secrets are valid, `503 {"status":"degraded",...}` otherwise —
use it as the platform health check.

---

## Option A — Koyeb (free tier, no credit card)

Koyeb's free "nano" instance needs no card and runs one always-on
service.

1. Push this repo to GitHub.
2. Koyeb dashboard → **Create Web Service** → GitHub → this repo.
3. **Builder:** Dockerfile. **Work directory / context:** `server`.
   (Or Buildpack: it will pick up `server/Procfile` and `engines.node`.)
4. **Instance:** Free.
5. **Health check:** HTTP, path `/health`, port `8000` (Koyeb's default
   injected `PORT`) — the app reads `PORT`, so this just works.
6. **Environment variables:** add `GROQ_API_KEY`,
   `FIREBASE_SERVICE_ACCOUNT_JSON` (paste the full JSON), and
   `ALLOWED_ORIGINS`. Mark the two secrets as *Secret*.
7. Deploy. You get `https://<name>-<org>.koyeb.app`.

## Option B — Fly.io (generous free allowance; card on file required)

```
cd server
fly launch --no-deploy          # generates fly.toml; keep internal_port from $PORT
fly secrets set GROQ_API_KEY=...  FIREBASE_SERVICE_ACCOUNT_JSON='...'
fly secrets set ALLOWED_ORIGINS='https://rosiva.web.app'
fly deploy
```
`fly.toml` should set `[http_service] internal_port = 8080`,
`force_https = true`, and a `[[http_service.checks]]` on `/health`.

## Option C — Render (free web service; card required on the account)

`render.yaml` (Blueprint) is already in this folder. Dashboard →
**New + → Blueprint → pick the repo**, then set `GROQ_API_KEY` and
`FIREBASE_SERVICE_ACCOUNT_JSON` (both `sync:false`) and `ALLOWED_ORIGINS`.

## Option D — Railway / any buildpack host

`Procfile` (`web: node src/index.js`) + `package.json` `engines.node`
are enough. Set the env vars in the dashboard.

## Option E — Any Docker host / self-managed

```
cd server
docker build -t rosiva-ai-backend .
docker run -p 8080:8080 \
  -e GROQ_API_KEY=... \
  -e FIREBASE_SERVICE_ACCOUNT_JSON="$(cat serviceAccount.json)" \
  -e ALLOWED_ORIGINS="https://your-web-frontend" \
  rosiva-ai-backend
```
Put a TLS-terminating reverse proxy (Caddy/nginx/Traefik) in front for HTTPS.

---

## After the backend is live

1. `curl https://<backend-domain>/health` → expect `{"status":"ok",...}`.
2. From the repo root, with the real env vars exported:
   `node server/live-check.mjs` → expect `LIVE CHECKS: 34/34 passed`.
3. Build the web frontend pointing at it (see `../WEB_DEPLOYMENT.md`):
   `flutter build web --release --dart-define=AI_BACKEND_URL=https://<backend-domain>`
4. Set `ALLOWED_ORIGINS` on the backend to the deployed web origin and
   redeploy.

## Key rotation

New key in the Groq / Firebase console → update the env var on the host
→ redeploy → revoke the old key. No app rebuild needed (the key never
ships in a client).
