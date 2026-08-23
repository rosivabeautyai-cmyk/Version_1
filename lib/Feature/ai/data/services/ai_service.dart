import 'package:rosivia/core/network/api_client.dart';
import 'package:rosivia/core/network/api_exception.dart';
import 'package:rosivia/core/network/app_config.dart';

import '../models/chat_message_model.dart';

/// Talks to ROSIVA's own backend chat endpoint — never to Gemini
/// directly. The Gemini API key lives only on that server. This
/// class is deliberately the single choke point for AI calls so
/// swapping the underlying model/provider later never touches the
/// UI layer.
///
/// Expected backend contract (to be implemented server-side):
///   POST /chat
///   body: { "message": "...", "history": [ {role, text}, ... ] }
///   200 -> { "reply": "..." }
class AiService {
  final ApiClient _client;

  AiService({ApiClient? client})
      : _client = client ?? ApiClient(baseUrl: AppConfig.aiApiBaseUrl);

  bool get isConfigured => _client.isConfigured;

  Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
  }) async {
    if (!isConfigured) throw const ApiNotConfiguredException();

    final response = await _client.post(
      '/chat',
      body: {
        'message': message,
        'history': history
            .map((m) => {
                  'role': m.role == ChatRole.assistant ? 'assistant' : 'user',
                  'text': m.text,
                })
            .toList(),
      },
    );

    if (response is Map && response['reply'] is String) {
      return response['reply'] as String;
    }

    throw const ApiParsingException();
  }
}
