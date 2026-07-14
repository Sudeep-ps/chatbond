import 'dart:async';

import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/core/network/api_client.dart';
import 'package:chatbond/core/websocket/socket_service.dart';
import 'package:chatbond/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:dio/dio.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;
  final SocketService _socketService;
  final Map<String, String> _chatIdCache = {}; // "uidA-uidB" (sorted) -> chatId

  ChatRemoteDataSourceImpl(this._apiClient, this._socketService);

  Future<String?> _resolveImageKey(String? key) async {
    if (key == null || key.isEmpty) return key;
    try {
      final response =
          await _apiClient.dio.post('/storage/view-url', data: {'key': key});
      return response.data as String;
    } catch (_) {
      return null;
    }
  }

  Future<MessageEntity> _resolveMessage(MessageEntity m) async {
    if (m.messageType != MessageType.Image) return m;
    final url = await _resolveImageKey(m.content);
    return MessageEntity(
        id: m.id,
        senderID: m.senderID,
        content: url ?? m.content,
        messageType: m.messageType,
        sentAt: m.sentAt);
  }

  String _pairKey(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}-${sorted[1]}';
  }

  Future<String> _resolveChatId(String uid1, String uid2) async {
    final key = _pairKey(uid1, uid2);
    if (_chatIdCache.containsKey(key)) return _chatIdCache[key]!;
    try {
      final response =
          await _apiClient.dio.post('/chats', data: {'otherUserId': uid2});
      final chatId = response.data['id'] ?? response.data['_id'];
      _chatIdCache[key] = chatId;
      return chatId;
    } on DioException catch (e) {
      throw FirestoreException(
          e.response?.data['message']?.toString() ?? 'Could not resolve chat');
    }
  }

  @override
  Future<bool> checkChatExists(String uid1, String uid2) async {
    await _resolveChatId(
        uid1, uid2); // find-or-create is idempotent on the backend
    return true;
  }

  @override
  Future<void> createNewChat(String uid1, String uid2) async {
    await _resolveChatId(uid1, uid2);
  }

  @override
  Future<void> createUserProfile(UserProfileEntity userProfile) async {
    try {
      await _apiClient.dio.patch('/users/me', data: {
        'name': userProfile.name,
        if (userProfile.pfpURL != null) 'pfpUrl': userProfile.pfpURL,
      });
    } on DioException catch (e) {
      throw FirestoreException(e.response?.data['message']?.toString() ??
          'Could not update profile');
    }
  }

  @override
  Future<UserProfileEntity> getCurrentUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      final profile = UserProfileEntity.fromJson(response.data);
      final resolvedUrl = await _resolveImageKey(profile.pfpURL);
      return UserProfileEntity(
          uid: profile.uid, name: profile.name, pfpURL: resolvedUrl);
    } on DioException catch (e) {
      throw FirestoreException(
          e.response?.data['message']?.toString() ?? 'Could not load profile');
    }
  }

  @override
  Stream<List<UserProfileEntity>> getUserProfiles() {
    // one-shot fetch (REST, not a live Firestore stream) — refresh by re-watching the provider
    return Stream.fromFuture(_fetchProfiles(''));
  }

  @override
  Stream<List<UserProfileEntity>> searchUserProfiles(String query) {
    return Stream.fromFuture(_fetchProfiles(query));
  }

  Future<List<UserProfileEntity>> _fetchProfiles(String query) async {
    try {
      final response =
          await _apiClient.dio.get('/users', queryParameters: {'q': query});
      final profiles = (response.data as List)
          .map((j) => UserProfileEntity.fromJson(j))
          .toList();
      return Future.wait(profiles.map((p) async {
        final url = await _resolveImageKey(p.pfpURL);
        return UserProfileEntity(uid: p.uid, name: p.name, pfpURL: url);
      }));
    } on DioException catch (e) {
      throw FirestoreException(
          e.response?.data['message']?.toString() ?? 'Could not load users');
    }
  }

  @override
  Future<void> sendMessage(
      String uid1, String uid2, MessageEntity message) async {
    final chatId = await _resolveChatId(uid1, uid2);
    _socketService.sendMessage({
      'chatId': chatId,
      'content': message.content,
      'messageType':
          message.messageType == MessageType.Image ? 'IMAGE' : 'TEXT',
    });
  }

  @override
  Stream<ChatEntity> getChatData(String uid1, String uid2) {
    late final Stream<ChatEntity> stream;
    final controller = StreamController<ChatEntity>.broadcast(
      onCancel: () {},
    );

    () async {
      try {
        final chatId = await _resolveChatId(uid1, uid2);
        final history = await _apiClient.dio
            .get('/chats/$chatId/messages', queryParameters: {'take': 50});
        final messages = await Future.wait(
          (history.data as List)
              .map((j) => MessageEntity.fromJson(j))
              .toList()
              .reversed
              .map(_resolveMessage),
        );

        controller.add(ChatEntity(
            id: chatId, participants: [uid1, uid2], messages: messages));

        _socketService.joinChat(chatId);
        _socketService.onNewMessage((data) async {
          final incomingChatId = data['chatId'] ?? chatId;
          if (incomingChatId != chatId) return;
          final rawMessage = MessageEntity.fromJson(
              data is Map && data['message'] != null ? data['message'] : data);
          final newMessage = await _resolveMessage(rawMessage);
          messages.add(newMessage);
          controller.add(ChatEntity(
              id: chatId,
              participants: [uid1, uid2],
              messages: List.of(messages)));
        });
      } catch (e) {
        controller.addError(FirestoreException('Error loading chat: $e'));
      }
    }();

    stream = controller.stream;
    return stream;
  }
}
