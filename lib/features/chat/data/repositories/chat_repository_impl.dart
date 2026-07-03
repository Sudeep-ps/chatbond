import 'package:chatbond/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<bool> checkChatExists(String uid1, String uid2) {
    return _remoteDataSource.checkChatExists(uid1, uid2);
  }

  @override
  Future<void> createNewChat(String uid1, String uid2) {
    return _remoteDataSource.createNewChat(uid1, uid2);
  }

  @override
  Future<void> createUserProfile(UserProfileEntity userProfile) {
    return _remoteDataSource.createUserProfile(userProfile);
  }

  @override
  Future<UserProfileEntity> getCurrentUserProfile() {
    return _remoteDataSource.getCurrentUserProfile();
  }

  @override
  Stream<ChatEntity> getChatData(String uid1, String uid2) {
    return _remoteDataSource.getChatData(uid1, uid2);
  }

  @override
  Stream<List<UserProfileEntity>> getUserProfiles() {
    return _remoteDataSource.getUserProfiles();
  }

  @override
  Stream<List<UserProfileEntity>> searchUserProfiles(String query) {
    return _remoteDataSource.searchUserProfiles(query);
  }

  @override
  Future<void> sendMessage(String uid1, String uid2, MessageEntity message) {
    return _remoteDataSource.sendMessage(uid1, uid2, message);
  }
}
