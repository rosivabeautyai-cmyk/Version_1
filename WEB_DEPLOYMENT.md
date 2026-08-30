# ROSIVA Flutter Web — production deployment

The Flutter Web build is a pure static bundle (`build/web`). It talks to
Firebase (Auth + Firestore) with the **public** Firebase Web config that
is already in `lib/firebase_options.dart`, and to the ROSIVA AI backend
over HTTPS. **No Groq key and no Firebase service account are in the web
build** — the only backend-specific value it needs is the backend URL.

## 1. Build

```powershell
# Local backend
flutter build web --release --dart-define=AI_BACKEND_URL=http://localhost:8080

# Production
flutter build web --release --dart-define=AI_BACKEND_URL=https://<backend-domain>
```

`AI_BACKEND_URL` is read by `AppConfig.aiBackendBaseUrl`
(`String.fromEnvironment`). If it is omitted the AI screen shows a
"not connected yet" state; the rest of the app (catalog, auth, admin)
still works. Mobile builds are unaffected — they pass the same define
(`--dart-define=AI_BACKEND_URL=...`) to `flutter build apk` / `ipa`.

If you serve the app from a sub-path (not the domain root), add
`--base-href=/your/path/`.

## 2. Host the static bundle (all free, no credit card)

### Firebase Hosting (same project — recommended)
`firebase.json` already has a `hosting` block pointing at `build/web`
with an SPA rewrite and sensible cache headers.

```powershell
firebase deploy --only hosting
```

Gives `https://rosiva-24fa4.web.app` (and `…firebaseapp.com`). Firebase
Hosting on the Spark (free) plan needs no card.

### Alternatives
- **Cloudflare Pages / Netlify / GitHub Pages / Vercel (static):** point
  them at the `build/web` output (or a build command
  `flutter build web --release --dart-define=AI_BACKEND_URL=…`). All have
  free tiers without a card. Configure a SPA fallback to `index.html`.

## 3. Wire the two together

1. Deploy the backend first (`server/DEPLOYMENT.md`) and note its URL.
2. On the backend, set `ALLOWED_ORIGINS` to the web origin(s), e.g.
   `https://rosiva-24fa4.web.app,https://rosiva-24fa4.firebaseapp.com`,
   and redeploy.
3. Build web with `--dart-define=AI_BACKEND_URL=https://<backend-domain>`
   and deploy.
4. In the **Firebase console → Authentication → Settings → Authorized
   domains**, add the web hosting domain so Firebase Auth works there.

## Known web-specific notes (not build blockers)

- **Google Sign-In on web** needs a *Web* OAuth 2.0 Client ID. Add
  `<meta name="google-signin-client_id" content="<web-client-id>">` to
  `web/index.html` (or pass `clientId:` to `GoogleSignIn`). Until then,
  email/password sign-in works on web; the Google button will fail at
  runtime only. Apple Sign-In is already hidden on web
  (`AuthService.isAppleSignInAvailable` returns false for `kIsWeb`).
- **Firebase Web API key** in `lib/firebase_options.dart` is a public
  client identifier, not a secret — it is safe in the web bundle and is
  protected by Firestore Security Rules + Firebase Auth.
- `speech_to_text` / `flutter_tts` are declared in `pubspec.yaml` but not
  imported anywhere in `lib/`; they compile fine for web (JS) and are
  inert. They can be removed from `pubspec.yaml` later as cleanup.
- `lib/core/network/api_client.dart` imports `dart:io` but is **dead
  code** (nothing imports it), so it is not part of the web compilation.
  Delete it or make it web-safe as future cleanup.
