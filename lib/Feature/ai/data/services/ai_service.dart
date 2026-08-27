import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../products/data/models/product_model.dart';
import '../models/chat_message_model.dart';

/// The user's latest message, understood by Gemini: either a plain
/// beauty question (answered directly) or a product request (in
/// which case [category]/[productType]/[keywords]/[maxPrice] drive a
/// real Firestore/catalog search — Gemini never invents products).
class ProductSearchIntent {
  final bool needsProducts;
  final String? category;
  final String? productType;
  final List<String> keywords;
  final double? maxPrice;
  final String? answer;

  const ProductSearchIntent({
    required this.needsProducts,
    this.category,
    this.productType,
    this.keywords = const [],
    this.maxPrice,
    this.answer,
  });

  factory ProductSearchIntent.fromJson(Map<String, dynamic> json) {
    return ProductSearchIntent(
      needsProducts: json['needsProducts'] as bool? ?? false,
      category: json['category'] as String?,
      productType: json['productType'] as String?,
      keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      answer: json['answer'] as String?,
    );
  }
}

/// Talks to Gemini directly through Firebase AI Logic (Gemini Developer
/// API backend) — no custom server, no API key in the client. This
/// class is the single choke point for AI calls so the model can be
/// swapped without touching the UI layer.
class AiService {
  /// Single place to change the Gemini model used by the assistant.
  static const String _modelName = 'gemini-3.7-flash';

  static const String _systemInstruction =
      'You are ROSIVA AI, a friendly, elegant, concise beauty assistant '
      'for skincare, makeup, perfume, and beauty routines. Keep answers '
      'brief and helpful. You are not a doctor: never diagnose, guarantee '
      'outcomes, or replace professional medical advice — for serious or '
      'medical skin concerns, tell the user to consult a dermatologist. '
      'Reply in the same language the user writes in (English or Arabic).';

  static const String _intentSystemInstruction =
      "You are ROSIVA AI's request analyzer. Given the user's latest "
      'message and recent conversation context, decide: is the user '
      'asking to be shown/recommended/find a product to buy '
      '(needsProducts=true), or asking a general beauty question/chatting '
      '(needsProducts=false)? '
      'If true: fill category (one of skincare, makeup, perfume, or '
      "null), productType (a short keyword like 'moisturizer'), keywords "
      '(extra descriptive words), maxPrice (a number if a budget was '
      "mentioned, else null); leave 'answer' empty. "
      'The product catalog itself is in English, regardless of what '
      'language the user writes in — so category, productType, and '
      'keywords must ALWAYS be in English (translate them if the user '
      "wrote in Arabic), even though 'answer' (for the false case) must "
      "still match the user's own language. "
      "If false: leave category/productType/keywords/maxPrice empty, and "
      "instead write a short, friendly, concise answer in 'answer', in "
      'the same language the user wrote in. You are a premium beauty '
      'assistant for skincare, makeup, perfume, and beauty routines — '
      'never diagnose, guarantee outcomes, or replace professional '
      'medical advice; for serious/medical skin concerns, tell the user '
      'to consult a dermatologist.';

  /// How many prior turns (user + assistant) to send as context,
  /// keeping token usage bounded.
  static const int _maxHistoryTurns = 10;

  GenerativeModel? _model;
  GenerativeModel? _intentModel;

  GenerativeModel get _generativeModel {
    return _model ??= FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(maxOutputTokens: 400),
    );
  }

  GenerativeModel get _intentGenerativeModel {
    return _intentModel ??= FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_intentSystemInstruction),
      generationConfig: GenerationConfig(
        maxOutputTokens: 300,
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'needsProducts': Schema.boolean(),
            'category': Schema.string(nullable: true),
            'productType': Schema.string(nullable: true),
            'keywords': Schema.array(items: Schema.string()),
            'maxPrice': Schema.number(nullable: true),
            'answer': Schema.string(nullable: true),
          },
          optionalProperties: [
            'category',
            'productType',
            'keywords',
            'maxPrice',
            'answer',
          ],
        ),
      ),
    );
  }

  bool get isConfigured => true;

  List<Content> _historyContent(List<ChatMessageModel> history) {
    // `history` already includes the just-added current user message
    // (see AiChatProvider) — use everything before it as prior
    // context, capped to the most recent turns.
    final priorTurns = history.length > 1
        ? history.sublist(0, history.length - 1)
        : const <ChatMessageModel>[];
    final recentTurns = priorTurns.length > _maxHistoryTurns
        ? priorTurns.sublist(priorTurns.length - _maxHistoryTurns)
        : priorTurns;

    return recentTurns
        .map((m) => Content(m.isUser ? 'user' : 'model', [TextPart(m.text)]))
        .toList();
  }

  Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  }) async {
    final chat = _generativeModel.startChat(history: _historyContent(history));
    final response = await chat.sendMessage(Content.text(message));
    final reply = response.text?.trim();

    if (reply == null || reply.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return reply;
  }

  /// Single Gemini call that both classifies the message and either
  /// extracts a product-search intent or (for general questions)
  /// produces the final conversational answer directly — avoiding a
  /// second call for the common non-product case.
  Future<ProductSearchIntent> analyzeIntent({
    required String message,
    required List<ChatMessageModel> history,
  }) async {
    final chat =
        _intentGenerativeModel.startChat(history: _historyContent(history));
    final response = await chat.sendMessage(Content.text(message));
    final raw = response.text;

    if (raw == null || raw.isEmpty) {
      throw Exception('Empty intent response from Gemini');
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ProductSearchIntent.fromJson(decoded);
  }

  /// Short, grounded explanation for a small set of *real* products
  /// already fetched from the catalog. Only minimal fields are sent —
  /// never the full catalog, descriptions, or ingredients.
  Future<String> explainRecommendations({
    required String userMessage,
    required List<ProductModel> products,
  }) async {
    final summary = products.map((p) {
      final price =
          p.price != null ? '${p.price} ${p.currency}' : 'price unavailable';
      final brand = p.brand != null ? ' by ${p.brand}' : '';
      final category = p.category != null ? ', category: ${p.category}' : '';
      return '- ${p.name}$brand ($price)$category';
    }).join('\n');

    final prompt = 'The user asked: "$userMessage".\n'
        'These real ROSIVA products matched:\n$summary\n\n'
        'In 1-3 short sentences, explain why these may be worth exploring '
        "for the user's request. Use cautious language (\"may be "
        'suitable", "may be worth exploring") — never guarantee results '
        'or make medical claims. Do not invent any product not listed '
        'above. Reply in the same language as the user.';

    final response = await _generativeModel.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '';
  }
}
