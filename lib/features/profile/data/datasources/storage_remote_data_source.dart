import 'dart:io';

abstract class StorageRemoteDataSource {
  Future<String?> uploadUserProfilePicture(File file, String uid);
  Future<String?> uploadChatImage(File file, String chatID);
  Future<void> deleteProfilePicture(String imageUrl);
}
