/// Centralized runtime configuration.
///
/// ROSIVA never embeds API keys or secrets inside the Flutter client.
/// The product catalog reads directly from Firestore (see
/// `Feature/products/data/services/product_api_service.dart`).
///
/// The AI assistant now talks to the ROSIVA AI backend (a small
/// Node/Express service — see `/server`), which is the only place the
/// Groq API key exists. The client only needs that backend's *base URL*
/// (not a secret — it's a public HTTPS endpoint).
///
/// It defaults to the production backend so a plain `flutter run` /
/// `flutter build` just works. Override it only for local backend
/// development, or to point at a different deployment:
///
///   flutter run --dart-define=AI_BACKEND_URL=http://10.0.2.2:8080
///
/// Setting it to an empty string explicitly makes the AI screen show a
/// "not connected yet" state instead of calling out.
abstract class AppConfig {
  /// Network request timeout used by [ApiClient]-based services.
  static const Duration requestTimeout = Duration(seconds: 20);

  /// Base URL of the ROSIVA AI backend (`POST /api/ai/chat`).
  /// Overridable via `--dart-define=AI_BACKEND_URL=...`; defaults to the
  /// live production backend.
  static const String aiBackendBaseUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'https://version-1-yhjf.onrender.com',
  );

  /// Longer timeout for the AI chat call specifically — the backend
  /// may itself be waiting on an LLM round-trip (and a free-tier host
  /// like Render can cold-start).
  static const Duration aiRequestTimeout = Duration(seconds: 45);
}
