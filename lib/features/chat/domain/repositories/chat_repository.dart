import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';

abstract class ChatRepository {
  // User related
  Future<UserProfileEntity> getCurrentUserProfile();
  Stream<List<UserProfileEntity>> getUserProfiles();
  Stream<List<UserProfileEntity>> searchUserProfiles(String query);
  Future<void> createUserProfile(UserProfileEntity userProfile);

  // Chat related
  Future<bool> checkChatExists(String uid1, String uid2);
  Future<void> createNewChat(String uid1, String uid2);
  Future<void> sendMessage(String uid1, String uid2, MessageEntity message);
  Stream<ChatEntity> getChatData(String uid1, String uid2);
}
