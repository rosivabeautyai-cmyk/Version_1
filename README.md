# rosivia

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## ROSIVA AI Backend

The in-app AI beauty assistant no longer calls Gemini / Firebase AI Logic
directly. It now calls a small backend that keeps the LLM key server-side.

```
Flutter (AiBackendService)
  → ROSIVA AI backend  (/server, Node + Express)
    → Groq API                    (intent extraction + short reply)
    → Firestore product search    (Admin SDK)
    → hard women's-beauty filter  (isRosivaProduct==true, gender==women, category∈{skincare,makeup,perfume})
  → { reply, intent, products[] } → existing Flutter chat + product UI
```

**The Groq API key exists only on the backend** (`GROQ_API_KEY`). It is never
in Flutter source, Dart constants, `.env` files shipped with the app, Android/iOS
resources, Remote Config, or Firestore.

### Configure the key locally (never paste it into chat or commit it)

```powershell
cd server
Copy-Item .env.example .env
# then edit .env and set:
#   GROQ_API_KEY   = your key from https://console.groq.com/keys
#   GROQ_MODEL     = llama-3.3-70b-versatile   (or any current free model)
#   FIREBASE_SERVICE_ACCOUNT_JSON = <full service-account JSON on one line>
```

Or set it per-session without a file:

```powershell
$env:GROQ_API_KEY = "YOUR_KEY"
```

### Run the backend

```powershell
cd server
npm install
npm run dev        # http://localhost:8080  (GET /health, POST /api/ai/chat)
npm test           # intent + hard-filter + security test suites
```

### Point the Flutter app at it

The backend URL is a build-time define, never hard-coded:

```powershell
# Android emulator -> host machine is 10.0.2.2
flutter run --dart-define=AI_BACKEND_URL=http://10.0.2.2:8080

# Release build against the deployed backend
flutter build apk --dart-define=AI_BACKEND_URL=https://rosiva-ai-backend.onrender.com
```

With no `AI_BACKEND_URL` the AI screen shows a "not connected yet" state.

### Deploy (Render.com free tier)

`server/render.yaml` is a Render blueprint. Push the repo to GitHub, then in
Render: **New + → Blueprint → pick the repo**. Set `GROQ_API_KEY` and
`FIREBASE_SERVICE_ACCOUNT_JSON` as dashboard secrets (they are `sync:false` in
the blueprint, so never committed). Render provides HTTPS and pings `/health`.
Free instances sleep after ~15 min idle; the Flutter client uses a 45 s timeout
to absorb the cold start.

### Rotate the key

Create a new key at <https://console.groq.com/keys>, update `GROQ_API_KEY` in
the Render dashboard (or your local `.env`), redeploy/restart, then delete the
old key in the Groq console. No app update or store release is needed — the key
never ships in the client.

Full details, request/response shape, and the safety model are in
[`server/README.md`](server/README.md).
