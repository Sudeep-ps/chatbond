enum MessageType { Text, Image }

class MessageEntity {
  final String id;
  final String senderID;
  final String content;
  final MessageType messageType;
  final DateTime sentAt;

  MessageEntity({
    this.id = '',
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] ?? json['senderId'];
    return MessageEntity(
      id: json['id'] ?? json['_id'] ?? '',
      senderID: sender is Map
          ? (sender['id'] ?? sender['_id'] ?? '')
          : (sender ?? ''),
      content: json['content'] ?? '',
      messageType:
          json['messageType'] == 'IMAGE' ? MessageType.Image : MessageType.Text,
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'messageType': messageType == MessageType.Image ? 'IMAGE' : 'TEXT',
    };
  }
}
