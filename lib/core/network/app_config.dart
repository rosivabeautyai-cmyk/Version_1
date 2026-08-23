/// Centralized runtime configuration.
///
/// ROSIVA never embeds API keys or secrets inside the Flutter client.
/// Every URL below is injected at build/run time via `--dart-define`
/// (e.g. `flutter run --dart-define=API_BASE_URL=https://api.rosiva.app`)
/// and points at a backend that itself holds the real credentials
/// (product catalog service, and — for the AI assistant — a secure
/// proxy in front of Gemini). Until those backends are connected the
/// values are simply empty, and the app degrades gracefully to a
/// "not configured yet" state instead of ever crashing or shipping
/// fake data.
abstract class AppConfig {
  /// Base URL of the ROSIVA product/catalog REST API.
  ///
  /// Expected endpoints (final paths are decided by the backend team):
  ///   GET /categories
  ///   GET /products?category=&query=&page=&limit=
  ///   GET /products/{id}
  static const String productsApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Base URL of the secure backend proxy that forwards chat turns to
  /// Gemini. The Gemini API key itself lives only on that server —
  /// never inside this app.
  static const String aiApiBaseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: '',
  );

  static bool get isProductsApiConfigured => productsApiBaseUrl.isNotEmpty;

  static bool get isAiApiConfigured => aiApiBaseUrl.isNotEmpty;

  /// Network request timeout used by every service in the app.
  static const Duration requestTimeout = Duration(seconds: 20);
}
