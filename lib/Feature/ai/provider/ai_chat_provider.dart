import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';

import '../../products/data/models/category_model.dart';
import '../../products/data/models/product_model.dart';
import '../../products/data/models/product_query.dart';
import '../../products/data/repositories/product_repository.dart';
import '../data/models/chat_message_model.dart';
import '../data/services/ai_service.dart';

class AiChatProvider extends ChangeNotifier {
  final AiService _service;
  final ProductRepository _productRepository;

  AiChatProvider({AiService? service, ProductRepository? productRepository})
      : _service = service ?? AiService(),
        _productRepository = productRepository ?? ProductRepository();

  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  bool get isConfigured => _service.isConfigured;

  bool _isSending = false;
  bool get isSending => _isSending;

  int _idCounter = 0;
  String _nextId() => 'msg_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  Future<void> sendMessage(
    String text, {
    String errorFallback = 'Something went wrong. Please try again.',
    String noResultsFallback = "I couldn't find a matching product right now.",
    String recommendationsIntroFallback = 'Here are some products that may be relevant.',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    final userMessage = ChatMessageModel(
      id: _nextId(),
      role: ChatRole.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isSending = true;
    notifyListeners();

    try {
      final intent = await _service.analyzeIntent(
        message: trimmed,
        history: _messages,
      );

      if (!intent.needsProducts) {
        final answer = intent.answer?.trim();
        _messages.add(
          ChatMessageModel(
            id: _nextId(),
            role: ChatRole.assistant,
            text: (answer != null && answer.isNotEmpty) ? answer : errorFallback,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        final products = await _findProducts(intent);

        if (products.isEmpty) {
          _messages.add(
            ChatMessageModel(
              id: _nextId(),
              role: ChatRole.assistant,
              text: noResultsFallback,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          var explanation = '';
          try {
            explanation = await _service.explainRecommendations(
              userMessage: trimmed,
              products: products,
            );
          } catch (_) {
            // Explanation is a nice-to-have; still show the real
            // products even if this secondary call fails.
          }

          _messages.add(
            ChatMessageModel(
              id: _nextId(),
              role: ChatRole.assistant,
              text: explanation.trim().isNotEmpty
                  ? explanation.trim()
                  : recommendationsIntroFallback,
              products: products,
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      // Never surface raw exception details to the user (could leak
      // backend/config info) — but logging in debug builds is the
      // only way to tell "Gemini call failed" apart from "Firestore
      // product lookup failed" apart from "App Check rejected the
      // request" when something breaks.
      debugPrint('ROSIVA AI: catalog request failed — $e');
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: errorFallback,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ROSIVA AI: unhandled error — $e');
      debugPrintStack(stackTrace: stackTrace);
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: errorFallback,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Queries the existing product catalog, then ranks the results
  /// locally so Gemini is never asked to sort or, worse, invent
  /// products.
  ///
  /// When the AI identified a ROSIVA category, that's applied as a
  /// real Firestore `category` filter — a reliable, always-English
  /// field regardless of what language the user wrote in. `searchTerm`
  /// is only sent to Firestore as a fallback when no category was
  /// identified, since (unlike `category`) it's a hard substring
  /// filter that can zero out every real match if the extracted term
  /// doesn't literally appear in the (English) catalog text. Keyword/
  /// productType relevance is still applied afterwards, but only as
  /// local *ranking* (see `score` below), never as an exclusion.
  Future<List<ProductModel>> _findProducts(ProductSearchIntent intent) async {
    // Routed through the single canonical `normalizeCategory` (same
    // one the product model/query layer uses) rather than comparing
    // Gemini's raw string directly — never scatter category-string
    // logic across screens/providers.
    final normalizedCategory = normalizeCategory(intent.category);
    final hasCategory = normalizedCategory != null;
    final fallbackSearchTerm = intent.productType ??
        (intent.keywords.isNotEmpty ? intent.keywords.first : intent.category);

    final page = await _productRepository.getProducts(
      ProductQuery(
        category: hasCategory ? normalizedCategory : null,
        searchTerm: hasCategory ? null : fallbackSearchTerm,
        limit: 30,
      ),
    );

    var candidates = page.items;

    if (intent.maxPrice != null) {
      candidates = candidates.where((p) {
        if (p.price == null) return true;
        // Only compare prices in the same currency — never guess an
        // exchange rate or make a false cross-currency comparison.
        if (p.currency.toUpperCase() != 'USD') return true;
        return p.price! <= intent.maxPrice!;
      }).toList();
    }

    final keywords = <String>[
      if (intent.category != null) intent.category!,
      if (intent.productType != null) intent.productType!,
      ...intent.keywords,
    ].map((k) => k.toLowerCase()).where((k) => k.isNotEmpty).toList();

    int score(ProductModel p) {
      var s = 0;
      // `p.category` is already normalized (ProductModel.fromJson
      // runs every category through `normalizeCategory`), so this is
      // a direct canonical-slug comparison, not a raw string one.
      if (normalizedCategory != null && p.category == normalizedCategory) {
        s += 3;
      }
      final haystack = [p.category, p.name, p.brand, ...p.tags]
          .whereType<String>()
          .map((e) => e.toLowerCase())
          .join(' ');
      for (final k in keywords) {
        if (haystack.contains(k)) s += 1;
      }
      if (p.rating != null) s += p.rating!.round();
      if (p.isEditorsChoice) s += 1;
      return s;
    }

    candidates.sort((a, b) => score(b).compareTo(score(a)));

    return candidates.take(5).toList();
  }
}
