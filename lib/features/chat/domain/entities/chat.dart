import 'package:chatbond/features/chat/domain/entities/message.dart';

class ChatEntity {
  final String id;
  final List<String> participants;
  final List<MessageEntity> messages;

  ChatEntity({
    required this.id,
    required this.participants,
    required this.messages,
  });

  factory ChatEntity.fromJson(Map<String, dynamic> json) {
    return ChatEntity(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      messages: List.from(json['messages'] ?? [])
          .map((m) => MessageEntity.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}
