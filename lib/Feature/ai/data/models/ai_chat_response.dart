import '../../../products/data/models/product_model.dart';

/// Structured intent the backend extracted for the user's message.
/// `gender` is always `women` — the backend imposes it and never
/// echoes whatever the LLM guessed.
class AiIntent {
  final String? category;
  final String? productType;
  final String gender;

  const AiIntent({this.category, this.productType, this.gender = 'women'});

  factory AiIntent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AiIntent();
    return AiIntent(
      category: json['category'] as String?,
      productType: json['productType'] as String?,
      gender: json['gender'] as String? ?? 'women',
    );
  }
}

/// Response of `POST /api/ai/chat`.
///
/// [reply] is conversational text the backend produced (LLM-generated
/// for the "here are products" case, deterministic localized copy for
/// the out-of-scope / no-results / error cases). [products] are REAL
/// catalog products the backend fetched from Firestore and hard-
/// filtered — the client renders them with the existing product UI and
/// never treats [reply] as a source of product data.
class AiChatResponse {
  final String reply;
  final AiIntent intent;
  final List<ProductModel> products;

  /// Non-null only for the backend's friendly error envelopes
  /// (`rate_limited`, `ai_unavailable`, `catalog_unavailable`, ...).
  final String? errorCode;

  const AiChatResponse({
    required this.reply,
    this.intent = const AiIntent(),
    this.products = const [],
    this.errorCode,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return AiChatResponse(
      reply: (json['reply'] as String?)?.trim() ?? '',
      intent: AiIntent.fromJson(json['intent'] as Map<String, dynamic>?),
      products: rawProducts is List
          ? rawProducts
              .whereType<Map<String, dynamic>>()
              .map(ProductModel.fromJson)
              .toList()
          : const [],
      errorCode: json['error'] as String?,
    );
  }
}
