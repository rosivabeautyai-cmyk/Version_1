// Provider-level tests for the migrated AI chat flow.
//
// After the Gemini -> ROSIVA-backend migration, [AiChatProvider] no
// longer talks to Firestore or an LLM directly: it sends the message +
// bounded history to [AiBackendService] and renders whatever structured
// [AiChatResponse] comes back. All women's-beauty hard filtering,
// product search, and intent extraction are proven in the backend test
// suite (server/test/*). These tests cover the Flutter side:
//   - real backend products are rendered on the assistant message
//   - bounded history is forwarded (prior turns, current message last)
//   - rate-limit vs generic failures map to the right localized copy
//   - the _isSending guard still blocks concurrent sends
import 'package:flutter_test/flutter_test.dart';

import 'package:rosivia/Feature/ai/data/models/ai_chat_response.dart';
import 'package:rosivia/Feature/ai/data/models/chat_message_model.dart';
import 'package:rosivia/Feature/ai/data/services/ai_backend_service.dart';
import 'package:rosivia/Feature/ai/provider/ai_chat_provider.dart';
import 'package:rosivia/Feature/products/data/models/product_model.dart';

class FakeAiBackendService implements AiBackendService {
  FakeAiBackendService({this.response, this.throwError});

  AiChatResponse? response;
  Object? throwError;

  int calls = 0;
  List<ChatMessageModel>? lastHistory;
  String? lastMessage;
  String? lastLocale;
  Duration delay = Duration.zero;

  @override
  bool get isConfigured => true;

  @override
  void resetConversation() {}

  @override
  void dispose() {}

  @override
  Future<AiChatResponse> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
    String? locale,
    String? country,
    String? currency,
  }) async {
    calls++;
    lastMessage = message;
    lastHistory = List.of(history);
    lastLocale = locale;
    if (delay != Duration.zero) await Future.delayed(delay);
    if (throwError != null) throw throwError!;
    return response ??
        const AiChatResponse(reply: 'ok', products: [], intent: AiIntent());
  }
}

ProductModel _product(String id) => ProductModel(
      id: id,
      name: 'Mascara $id',
      category: 'makeup',
      isRosivaProduct: true,
      gender: 'women',
      storeUrl: 'https://example.com/$id',
    );

void main() {
  group('AiChatProvider — migrated backend flow', () {
    test('renders backend-supplied products on the assistant message', () async {
      final fake = FakeAiBackendService(
        response: AiChatResponse(
          reply: 'لقيتلك شوية ماسكرا ❤️',
          intent: const AiIntent(category: 'makeup', productType: 'mascara'),
          products: [_product('1'), _product('2')],
        ),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage('عايزة ماسكرا');

      expect(provider.messages.length, 2);
      final assistant = provider.messages.last;
      expect(assistant.role, ChatRole.assistant);
      expect(assistant.text, 'لقيتلك شوية ماسكرا ❤️');
      expect(assistant.products, isNotNull);
      expect(assistant.products!.map((p) => p.id), ['1', '2']);
      expect(assistant.isError, isFalse);
    });

    test('no products -> assistant message with reply text and no cards',
        () async {
      final fake = FakeAiBackendService(
        response: const AiChatResponse(
          reply: 'معنديش منتجات مناسبة لطلبك حاليًا ❤️',
        ),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage('عايزة شامبو');

      final assistant = provider.messages.last;
      expect(assistant.text, contains('معنديش'));
      expect(assistant.products, isNull);
    });

    test('forwards bounded prior history with the current message last',
        () async {
      final fake = FakeAiBackendService(
        response: const AiChatResponse(reply: 'ok'),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage('عايزة ماسكرا');
      await provider.sendMessage('Waterproof');

      // On the 2nd call the service received the full running list
      // (2 prior turns + the new user message); the backend service
      // itself trims it to prior-only before the HTTP call.
      expect(fake.lastMessage, 'Waterproof');
      expect(fake.lastHistory!.first.text, 'عايزة ماسكرا');
      expect(fake.lastHistory!.last.text, 'Waterproof');
      expect(fake.lastHistory!.last.role, ChatRole.user);
    });

    test('rate-limit failure -> rateLimitFallback copy, flagged as error',
        () async {
      final fake = FakeAiBackendService(
        throwError: const AiRateLimitException(),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage(
        'عايزة ماسكرا',
        errorFallback: 'generic-error',
        rateLimitFallback: 'busy-try-later',
      );

      final assistant = provider.messages.last;
      expect(assistant.text, 'busy-try-later');
      expect(assistant.isError, isTrue);
    });

    test('unavailable failure -> errorFallback copy, flagged as error',
        () async {
      final fake = FakeAiBackendService(
        throwError: const AiUnavailableException(),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage(
        'عايزة ماسكرا',
        errorFallback: 'generic-error',
        rateLimitFallback: 'busy-try-later',
      );

      final assistant = provider.messages.last;
      expect(assistant.text, 'generic-error');
      expect(assistant.isError, isTrue);
    });

    test('_isSending guard blocks a concurrent send', () async {
      final fake = FakeAiBackendService(
        response: const AiChatResponse(reply: 'ok'),
      )..delay = const Duration(milliseconds: 50);
      final provider = AiChatProvider(service: fake);

      final first = provider.sendMessage('first');
      // Fires while the first call is still in flight.
      await provider.sendMessage('second');
      await first;

      expect(fake.calls, 1);
      expect(fake.lastMessage, 'first');
    });

    test('resetConversation clears the local transcript', () async {
      final fake = FakeAiBackendService(
        response: const AiChatResponse(reply: 'ok'),
      );
      final provider = AiChatProvider(service: fake);

      await provider.sendMessage('عايزة ماسكرا');
      expect(provider.messages, isNotEmpty);

      provider.resetConversation();
      expect(provider.messages, isEmpty);
    });
  });
}
