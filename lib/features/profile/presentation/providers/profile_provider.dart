import 'dart:io';

import 'package:chatbond/features/profile/data/datasources/media_local_data_source_impl.dart';
import 'package:chatbond/features/profile/data/datasources/storage_remote_data_source_impl.dart';
import 'package:chatbond/features/profile/data/repositories/media_repository_impl.dart';
import 'package:chatbond/features/profile/data/repositories/storage_repository_impl.dart';
import 'package:chatbond/features/profile/domain/repositories/media_repository.dart';
import 'package:chatbond/features/profile/domain/repositories/storage_repository.dart';
import 'package:chatbond/features/profile/domain/usecases/profile_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

// Image Picker Provider
final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

// Data Sources Providers
final storageRemoteDataSourceProvider =
    Provider<StorageRemoteDataSourceImpl>((ref) {
  final apiClient = ref.watch(apiClientProvider); // from auth_provider.dart
  return StorageRemoteDataSourceImpl(apiClient);
});

final mediaLocalDataSourceProvider = Provider<MediaLocalDataSourceImpl>((ref) {
  final imagePicker = ref.watch(imagePickerProvider);
  return MediaLocalDataSourceImpl(imagePicker);
});

// Repository Providers
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final dataSource = ref.watch(storageRemoteDataSourceProvider);
  return StorageRepositoryImpl(dataSource);
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final dataSource = ref.watch(mediaLocalDataSourceProvider);
  return MediaRepositoryImpl(dataSource);
});

// Use Cases Providers
final uploadProfilePictureUsecaseProvider =
    Provider<UploadProfilePictureUsecase>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadProfilePictureUsecase(repository);
});

final deleteProfilePictureUsecaseProvider =
    Provider<DeleteProfilePictureUsecase>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return DeleteProfilePictureUsecase(repository);
});

final uploadChatImageUsecaseProvider = Provider<UploadChatImageUsecase>((ref) {
  final repository = ref.watch(storageRepositoryProvider);
  return UploadChatImageUsecase(repository);
});

final getImageFromGalleryUsecaseProvider =
    Provider<GetImageFromGalleryUsecase>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return GetImageFromGalleryUsecase(repository);
});

// Notifiers

class UploadProfilePictureNotifier extends StateNotifier<AsyncValue<String?>> {
  UploadProfilePictureNotifier(this._usecase)
      : super(const AsyncValue.data(null));
  final UploadProfilePictureUsecase _usecase;

  Future<void> uploadProfilePicture(File file, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _usecase(file, uid));
  }
}

final uploadProfilePictureProvider =
    StateNotifierProvider<UploadProfilePictureNotifier, AsyncValue<String?>>(
        (ref) {
  final usecase = ref.watch(uploadProfilePictureUsecaseProvider);
  return UploadProfilePictureNotifier(usecase);
});

class DeleteProfilePictureNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteProfilePictureNotifier(this._usecase)
      : super(const AsyncValue.data(null));
  final DeleteProfilePictureUsecase _usecase;

  Future<void> deleteProfilePicture(String imageUrl) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _usecase(imageUrl));
  }
}

final deleteProfilePictureProvider =
    StateNotifierProvider<DeleteProfilePictureNotifier, AsyncValue<void>>(
        (ref) {
  final usecase = ref.watch(deleteProfilePictureUsecaseProvider);
  return DeleteProfilePictureNotifier(usecase);
});

class UploadChatImageNotifier extends StateNotifier<AsyncValue<String?>> {
  UploadChatImageNotifier(this._usecase) : super(const AsyncValue.data(null));
  final UploadChatImageUsecase _usecase;

  Future<void> uploadChatImage(File file, String chatID) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _usecase(file, chatID));
  }
}

final uploadChatImageProvider =
    StateNotifierProvider<UploadChatImageNotifier, AsyncValue<String?>>((ref) {
  final usecase = ref.watch(uploadChatImageUsecaseProvider);
  return UploadChatImageNotifier(usecase);
});

class GetImageFromGalleryNotifier extends StateNotifier<AsyncValue<File?>> {
  GetImageFromGalleryNotifier(this._usecase)
      : super(const AsyncValue.data(null));
  final GetImageFromGalleryUsecase _usecase;

  Future<void> getImageFromGallery() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _usecase());
  }
}

final getImageFromGalleryProvider =
    StateNotifierProvider<GetImageFromGalleryNotifier, AsyncValue<File?>>(
        (ref) {
  final usecase = ref.watch(getImageFromGalleryUsecaseProvider);
  return GetImageFromGalleryNotifier(usecase);
});
