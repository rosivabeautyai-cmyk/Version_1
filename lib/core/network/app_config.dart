/// Centralized runtime configuration.
///
/// ROSIVA never embeds API keys or secrets inside the Flutter client.
/// The product catalog now reads directly from Firestore (see
/// `Feature/products/data/services/product_api_service.dart`), and the
/// AI assistant talks to Gemini directly through Firebase AI Logic
/// (see `Feature/ai/data/services/ai_service.dart`) — neither has a
/// separate backend URL to configure here anymore.
abstract class AppConfig {
  /// Network request timeout used by [ApiClient]-based services.
  static const Duration requestTimeout = Duration(seconds: 20);
}
