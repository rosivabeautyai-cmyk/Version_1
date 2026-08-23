import 'package:flutter/material.dart';

import 'package:rosivia/core/network/api_exception.dart';

import '../data/models/chat_message_model.dart';
import '../data/services/ai_service.dart';

class AiChatProvider extends ChangeNotifier {
  final AiService _service;

  AiChatProvider({AiService? service}) : _service = service ?? AiService();

  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  bool get isConfigured => _service.isConfigured;

  bool _isSending = false;
  bool get isSending => _isSending;

  int _idCounter = 0;
  String _nextId() => 'msg_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  Future<void> sendMessage(String text) async {
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
      final reply = await _service.sendMessage(
        message: trimmed,
        history: _messages,
      );

      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: reply,
          timestamp: DateTime.now(),
        ),
      );
    } on ApiException catch (e) {
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: e.message,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } catch (_) {
      _messages.add(
        ChatMessageModel(
          id: _nextId(),
          role: ChatRole.assistant,
          text: 'Something went wrong. Please try again.',
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
