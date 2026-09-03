import 'chat_message.dart';

class ChatSession {
  final String id;
  String title;
  final String category; // 'AI Health Assistant', 'Symptom Checker', 'Health Analyzer'
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    this.category = 'AI Health Assistant',
    required this.messages,
    required this.createdAt,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    String? category,
    List<ChatMessage>? messages,
    DateTime? createdAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      messages: messages ?? List.from(this.messages),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

