import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rosivia/core/network/app_config.dart';

import '../models/ai_chat_response.dart';
import '../models/chat_message_model.dart';

/// Base type for every AI-backend failure. The provider maps these to
/// friendly, localized user copy — technical detail never reaches the
/// UI.
sealed class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}

/// The backend (or Groq behind it) is rate-limited — free-tier budget
/// exhausted for now. Retrying immediately will not help.
class AiRateLimitException extends AiException {
  final Duration? retryAfter;
  const AiRateLimitException([this.retryAfter])
      : super('AI assistant is rate-limited');
}

/// Transient: timeout, network error, backend 5xx / cold start,
/// malformed response.
class AiUnavailableException extends AiException {
  const AiUnavailableException([super.message = 'AI assistant is unavailable']);
}

/// No `AI_BACKEND_URL` was provided at build time.
class AiNotConfiguredException extends AiException {
  const AiNotConfiguredException()
      : super('AI assistant is not connected yet');
}

/// The single choke point for AI calls from Flutter.
///
/// Talks ONLY to the ROSIVA AI backend (`POST /api/ai/chat`) over
/// HTTPS. The Groq API key lives on that backend and never in this
/// app. This service is deliberately thin: request shaping, timeout,
/// and mapping transport/status failures to [AiException]s — all
/// product data, reply text, and safety filtering happen server-side.
class AiBackendService {
  final String _baseUrl;
  final http.Client _client;

  /// How many prior turns to send as context. Bounded to keep requests
  /// small against the free-tier budget.
  static const int maxHistoryTurns = 16;

  AiBackendService({String? baseUrl, http.Client? client})
      : _baseUrl = _trimTrailingSlash(baseUrl ?? AppConfig.aiBackendBaseUrl),
        _client = client ?? http.Client();

  static String _trimTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  bool get isConfigured => _baseUrl.isNotEmpty;

  /// Stateless backend — conversation context is sent on every call —
  /// so there is nothing to reset server-side. Kept for API symmetry
  /// with the provider's "new chat" affordance.
  void resetConversation() {}

  /// Sends [message] plus a bounded slice of [history] to the backend
  /// and returns its structured [AiChatResponse] (reply text + real
  /// catalog products + intent).
  ///
  /// Throws [AiNotConfiguredException] / [AiRateLimitException] /
  /// [AiUnavailableException] — never a raw transport error.
  Future<AiChatResponse> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
    String? locale,
    String? country,
    String? currency,
  }) async {
    if (!isConfigured) throw const AiNotConfiguredException();

    // `history` includes the just-added current user message — send
    // everything before it as prior context, most-recent turns only.
    final prior = history.length > 1
        ? history.sublist(0, history.length - 1)
        : const <ChatMessageModel>[];
    final recent = prior.length > maxHistoryTurns
        ? prior.sublist(prior.length - maxHistoryTurns)
        : prior;

    final payload = <String, dynamic>{
      'message': message,
      'history': [
        for (final m in recent)
          {'role': m.isUser ? 'user' : 'assistant', 'text': m.text},
      ],
      if (locale != null && locale.isNotEmpty) 'locale': locale,
      if (country != null && country.isNotEmpty) 'country': country,
      if (currency != null && currency.isNotEmpty) 'currency': currency,
    };

    final uri = Uri.parse('$_baseUrl/api/ai/chat');

    http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(AppConfig.aiRequestTimeout);
    } on TimeoutException {
      throw const AiUnavailableException('timeout');
    } on http.ClientException {
      // Covers connection-refused / DNS / TLS failures on every
      // platform (mobile + web) — the `http` package normalizes them.
      throw const AiUnavailableException('network');
    } catch (_) {
      // Any other transport-layer failure (e.g. a platform SocketException
      // on mobile) — never surface it raw.
      throw const AiUnavailableException('network');
    }

    if (res.statusCode == 429) {
      throw AiRateLimitException(_parseRetryAfter(res.headers['retry-after']));
    }

    Map<String, dynamic>? decoded;
    if (res.bodyBytes.isNotEmpty) {
      try {
        final parsed = jsonDecode(utf8.decode(res.bodyBytes));
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {
        decoded = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded == null) throw const AiUnavailableException('bad_response');
      return AiChatResponse.fromJson(decoded);
    }

    // 5xx (incl. backend "ai_unavailable" / "catalog_unavailable"
    // envelopes) and anything else -> transient.
    throw const AiUnavailableException();
  }

  static Duration? _parseRetryAfter(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final secs = int.tryParse(raw.trim());
    if (secs != null) return Duration(seconds: secs.clamp(0, 120));
    return null;
  }

  void dispose() => _client.close();
}
