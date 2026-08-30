/// Centralized runtime configuration.
///
/// ROSIVA never embeds API keys or secrets inside the Flutter client.
/// The product catalog reads directly from Firestore (see
/// `Feature/products/data/services/product_api_service.dart`).
///
/// The AI assistant now talks to the ROSIVA AI backend (a small
/// Node/Express service — see `/server`), which is the only place the
/// Groq API key exists. The client only needs that backend's base URL,
/// supplied at build/run time and never hard-coded:
///
///   flutter run --dart-define=AI_BACKEND_URL=http://10.0.2.2:8080
///   flutter build apk --dart-define=AI_BACKEND_URL=https://rosiva-ai-backend.onrender.com
///
/// When it's empty the AI screen shows a "not connected yet" state
/// instead of failing.
abstract class AppConfig {
  /// Network request timeout used by [ApiClient]-based services.
  static const Duration requestTimeout = Duration(seconds: 20);

  /// Base URL of the ROSIVA AI backend (`POST /api/ai/chat`). Empty
  /// unless provided via `--dart-define=AI_BACKEND_URL=...`.
  static const String aiBackendBaseUrl =
      String.fromEnvironment('AI_BACKEND_URL', defaultValue: '');

  /// Longer timeout for the AI chat call specifically — the backend
  /// may itself be waiting on an LLM round-trip (and a free-tier host
  /// like Render can cold-start).
  static const Duration aiRequestTimeout = Duration(seconds: 45);
}
