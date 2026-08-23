enum ChatRole { user, assistant }

/// A single turn in the ROSIVA AI conversation. Kept intentionally
/// simple (role + text + timestamp) so it can be persisted or sent
/// as-is to a backend chat endpoint.
class ChatMessageModel {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final bool isError;

  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == ChatRole.user;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      role: (json['role'] as String?) == 'assistant'
          ? ChatRole.assistant
          : ChatRole.user,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isError: json['isError'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role == ChatRole.assistant ? 'assistant' : 'user',
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
