import 'package:chatbond/features/chat/data/datasources/chat_remote_data_source_impl.dart';
import 'package:chatbond/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:chatbond/features/chat/domain/repositories/chat_repository.dart';
import 'package:chatbond/features/chat/domain/usecases/chat_usecases.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_remote_data_source.dart';

// Firebase Providers
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Data Source Provider
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return ChatRemoteDataSourceImpl(firestore, firebaseAuth);
});

// Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(dataSource);
});

// Use Cases Providers
final getCurrentUserProfileUsecaseProvider =
    Provider<GetCurrentUserProfileUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetCurrentUserProfileUsecase(repository);
});

final getUserProfilesUsecaseProvider = Provider<GetUserProfilesUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetUserProfilesUsecase(repository);
});

final searchUserProfilesUsecaseProvider =
    Provider<SearchUserProfilesUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SearchUserProfilesUsecase(repository);
});

final createUserProfileUsecaseProvider =
    Provider<CreateUserProfileUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return CreateUserProfileUsecase(repository);
});

final checkChatExistsUsecaseProvider = Provider<CheckChatExistsUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return CheckChatExistsUsecase(repository);
});

final createNewChatUsecaseProvider = Provider<CreateNewChatUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return CreateNewChatUsecase(repository);
});

final sendMessageUsecaseProvider = Provider<SendMessageUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUsecase(repository);
});

final getChatDataUsecaseProvider = Provider<GetChatDataUsecase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetChatDataUsecase(repository);
});

// State Providers

// Current User Profile
final currentUserProfileProvider =
    FutureProvider<UserProfileEntity?>((ref) async {
  final usecase = ref.watch(getCurrentUserProfileUsecaseProvider);
  try {
    return await usecase();
  } catch (e) {
    return null;
  }
});

// User Profiles List
final userProfilesProvider = StreamProvider<List<UserProfileEntity>>((ref) {
  final usecase = ref.watch(getUserProfilesUsecaseProvider);
  return usecase();
});

// Search User Profiles
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchedUserProfilesProvider =
    StreamProvider<List<UserProfileEntity>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final usecase = ref.watch(searchUserProfilesUsecaseProvider);
  return usecase(query);
});

// Chat Data
final selectedChatUserIdProvider = StateProvider<String?>((ref) => null);

final chatDataProvider =
    StreamProvider.family<ChatEntity, (String, String)>((ref, uids) {
  final getChatUsecase = ref.watch(getChatDataUsecaseProvider);
  return getChatUsecase(uids.$1, uids.$2);
});

// Create User Profile State Notifier
class CreateUserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  CreateUserProfileNotifier(this._createUserProfileUsecase)
      : super(const AsyncValue.data(null));
  final CreateUserProfileUsecase _createUserProfileUsecase;

  Future<void> createProfile(UserProfileEntity profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _createUserProfileUsecase(profile));
  }
}

final createUserProfileProvider =
    StateNotifierProvider<CreateUserProfileNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(createUserProfileUsecaseProvider);
  return CreateUserProfileNotifier(usecase);
});

// Send Message State Notifier
class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  SendMessageNotifier(this._sendMessageUsecase)
      : super(const AsyncValue.data(null));
  final SendMessageUsecase _sendMessageUsecase;

  Future<void> sendMessage(
      String uid1, String uid2, MessageEntity message) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _sendMessageUsecase(uid1, uid2, message));
  }
}

final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(sendMessageUsecaseProvider);
  return SendMessageNotifier(usecase);
});

// Check Chat Exists State Notifier
class CheckChatExistsNotifier extends StateNotifier<AsyncValue<bool>> {
  CheckChatExistsNotifier(this._checkChatExistsUsecase)
      : super(const AsyncValue.data(false));
  final CheckChatExistsUsecase _checkChatExistsUsecase;

  Future<void> checkExists(String uid1, String uid2) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkChatExistsUsecase(uid1, uid2));
  }
}

final checkChatExistsProvider =
    StateNotifierProvider<CheckChatExistsNotifier, AsyncValue<bool>>((ref) {
  final usecase = ref.watch(checkChatExistsUsecaseProvider);
  return CheckChatExistsNotifier(usecase);
});

// Create Chat State Notifier
class CreateChatNotifier extends StateNotifier<AsyncValue<void>> {
  CreateChatNotifier(this._createNewChatUsecase)
      : super(const AsyncValue.data(null));
  final CreateNewChatUsecase _createNewChatUsecase;

  Future<void> createChat(String uid1, String uid2) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _createNewChatUsecase(uid1, uid2));
  }
}

final createChatProvider =
    StateNotifierProvider<CreateChatNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(createNewChatUsecaseProvider);
  return CreateChatNotifier(usecase);
});
