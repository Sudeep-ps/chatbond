import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { Text, Image }

class MessageEntity {
  final String senderID;
  final String content;
  final MessageType messageType;
  final Timestamp sentAt;

  MessageEntity({
    required this.senderID,
    required this.content,
    required this.messageType,
    required this.sentAt,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      senderID: json['senderID'] ?? '',
      content: json['content'] ?? '',
      messageType: MessageType.values.byName(json['messageType'] ?? 'Text'),
      sentAt: json['sentAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderID': senderID,
      'content': content,
      'sentAt': sentAt,
      'messageType': messageType.name,
    };
  }
}
