import 'package:flutter/foundation.dart';

import '../data/models/chat_message_model.dart';
import '../data/services/ai_backend_service.dart';

/// Drives the ROSIVA AI chat screen.
///
/// All AI intelligence, product search, and women's-beauty safety
/// filtering now live in the ROSIVA AI backend (`/server`). This
/// provider only owns the local message list, the send guard, and
/// mapping [AiException]s to friendly localized copy supplied by the
/// screen. It never queries Firestore itself and never sees the Groq
/// API key.
class AiChatProvider extends ChangeNotifier {
  final AiBackendService _service;

  AiChatProvider({AiBackendService? service})
      : _service = service ?? AiBackendService();

  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  bool get isConfigured => _service.isConfigured;

  bool _isSending = false;
  bool get isSending => _isSending;

  int _idCounter = 0;
  String _nextId() =>
      'msg_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// Clears the on-device conversation. The backend is stateless, so
  /// this is purely local.
  void resetConversation() {
    if (_isSending) return;
    _service.resetConversation();
    _messages.clear();
    notifyListeners();
  }

  /// Sends [text] to the backend and appends the assistant reply
  /// (plus any real catalog products it returned).
  ///
  /// [errorFallback] / [rateLimitFallback] are localized strings from
  /// the screen — the only user-visible text on failure.
  Future<void> sendMessage(
    String text, {
    String errorFallback = 'Something went wrong. Please try again.',
    String rateLimitFallback =
        'The assistant is busy right now. Please try again in a moment.',
    String? locale,
    String? country,
    String? currency,
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
      final response = await _service.sendMessage(
        message: trimmed,
        history: _messages,
        locale: locale,
        country: country,
        currency: currency,
      );

      final reply = response.reply.trim();
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: reply.isNotEmpty ? reply : errorFallback,
          products: response.products.isEmpty ? null : response.products,
          timestamp: DateTime.now(),
          isError: reply.isEmpty,
        ),
      );
    } on AiRateLimitException catch (e) {
      debugPrint('ROSIVA AI: rate limited — $e');
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: rateLimitFallback,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } on AiException catch (e) {
      // Covers AiUnavailableException and AiNotConfiguredException —
      // never surface transport/backend detail to the user.
      debugPrint('ROSIVA AI: request failed — $e');
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
}
