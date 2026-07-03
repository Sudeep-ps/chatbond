import 'dart:io';
import 'package:chatbond/features/profile/domain/repositories/storage_repository.dart';
import 'package:chatbond/features/profile/domain/repositories/media_repository.dart';

class UploadProfilePictureUsecase {
  final StorageRepository repository;
  UploadProfilePictureUsecase(this.repository);

  Future<String?> call(File file, String uid) {
    return repository.uploadUserProfilePicture(file, uid);
  }
}

class DeleteProfilePictureUsecase {
  final StorageRepository repository;
  DeleteProfilePictureUsecase(this.repository);

  Future<void> call(String imageUrl) {
    return repository.deleteProfilePicture(imageUrl);
  }
}

class UploadChatImageUsecase {
  final StorageRepository repository;
  UploadChatImageUsecase(this.repository);

  Future<String?> call(File file, String chatID) {
    return repository.uploadChatImage(file, chatID);
  }
}

class GetImageFromGalleryUsecase {
  final MediaRepository repository;
  GetImageFromGalleryUsecase(this.repository);

  Future<File?> call() {
    return repository.getImageFromGallery();
  }
}
