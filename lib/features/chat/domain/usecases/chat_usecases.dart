import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/domain/repositories/chat_repository.dart';

class GetCurrentUserProfileUsecase {
  final ChatRepository repository;
  GetCurrentUserProfileUsecase(this.repository);

  Future<UserProfileEntity> call() {
    return repository.getCurrentUserProfile();
  }
}

class GetUserProfilesUsecase {
  final ChatRepository repository;
  GetUserProfilesUsecase(this.repository);

  Stream<List<UserProfileEntity>> call() {
    return repository.getUserProfiles();
  }
}

class SearchUserProfilesUsecase {
  final ChatRepository repository;
  SearchUserProfilesUsecase(this.repository);

  Stream<List<UserProfileEntity>> call(String query) {
    return repository.searchUserProfiles(query);
  }
}

class CreateUserProfileUsecase {
  final ChatRepository repository;
  CreateUserProfileUsecase(this.repository);

  Future<void> call(UserProfileEntity userProfile) {
    return repository.createUserProfile(userProfile);
  }
}

class CheckChatExistsUsecase {
  final ChatRepository repository;
  CheckChatExistsUsecase(this.repository);

  Future<bool> call(String uid1, String uid2) {
    return repository.checkChatExists(uid1, uid2);
  }
}

class CreateNewChatUsecase {
  final ChatRepository repository;
  CreateNewChatUsecase(this.repository);

  Future<void> call(String uid1, String uid2) {
    return repository.createNewChat(uid1, uid2);
  }
}

class SendMessageUsecase {
  final ChatRepository repository;
  SendMessageUsecase(this.repository);

  Future<void> call(String uid1, String uid2, MessageEntity message) {
    return repository.sendMessage(uid1, uid2, message);
  }
}

class GetChatDataUsecase {
  final ChatRepository repository;
  GetChatDataUsecase(this.repository);

  Stream<ChatEntity> call(String uid1, String uid2) {
    return repository.getChatData(uid1, uid2);
  }
}
