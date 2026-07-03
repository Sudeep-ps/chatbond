import 'dart:io';

import 'package:chatbond/features/profile/data/datasources/storage_remote_data_source.dart';
import 'package:chatbond/features/profile/domain/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  final StorageRemoteDataSource _remoteDataSource;

  StorageRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> deleteProfilePicture(String imageUrl) {
    return _remoteDataSource.deleteProfilePicture(imageUrl);
  }

  @override
  Future<String?> uploadChatImage(File file, String chatID) {
    return _remoteDataSource.uploadChatImage(file, chatID);
  }

  @override
  Future<String?> uploadUserProfilePicture(File file, String uid) {
    return _remoteDataSource.uploadUserProfilePicture(file, uid);
  }
}
