import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/core/utils/firebase_utils.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:chatbond/features/chat/domain/entities/chat.dart';
import 'package:chatbond/features/chat/domain/entities/message.dart';
import 'package:chatbond/features/chat/domain/entities/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  late CollectionReference<UserProfileEntity> _usersCollection;
  late CollectionReference<ChatEntity> _chatCollection;

  ChatRemoteDataSourceImpl(this._firestore, this._firebaseAuth) {
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _usersCollection = _firestore
        .collection('users')
        .withConverter<UserProfileEntity>(
            fromFirestore: (snapshot, _) =>
                UserProfileEntity.fromJson(snapshot.data()!),
            toFirestore: (profile, _) => profile.toJson());

    _chatCollection = _firestore.collection('chats').withConverter<ChatEntity>(
        fromFirestore: (snapshot, _) => ChatEntity.fromJson(snapshot.data()!),
        toFirestore: (chat, _) => chat.toJson());
  }

  String get _currentUserId {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirestoreException('User not authenticated');
    }
    return user.uid;
  }

  @override
  Future<bool> checkChatExists(String uid1, String uid2) async {
    try {
      final chatID = generateChatID(uid1: uid1, uid2: uid2);
      final result = await _chatCollection.doc(chatID).get();
      return result.exists;
    } on FirebaseException catch (e) {
      throw FirestoreException('Check chat exists failed: ${e.message}');
    } catch (e) {
      throw FirestoreException('Unknown error checking chat: $e');
    }
  }

  @override
  Future<void> createNewChat(String uid1, String uid2) async {
    try {
      final chatID = generateChatID(uid1: uid1, uid2: uid2);
      final chat = ChatEntity(
        id: chatID,
        participants: [uid1, uid2],
        messages: [],
      );
      await _chatCollection.doc(chatID).set(chat);
    } on FirebaseException catch (e) {
      throw FirestoreException('Create chat failed: ${e.message}');
    } catch (e) {
      throw FirestoreException('Unknown error creating chat: $e');
    }
  }

  @override
  Future<void> createUserProfile(UserProfileEntity userProfile) async {
    try {
      await _usersCollection.doc(userProfile.uid).set(userProfile);
    } on FirebaseException catch (e) {
      throw FirestoreException('Create user profile failed: ${e.message}');
    } catch (e) {
      throw FirestoreException('Unknown error creating profile: $e');
    }
  }

  @override
  Future<UserProfileEntity> getCurrentUserProfile() async {
    try {
      final uid = _currentUserId;
      final snapshot = await _usersCollection.doc(uid).get();
      if (!snapshot.exists) {
        throw FirestoreException('User profile not found');
      }
      return snapshot.data()!;
    } on FirebaseException catch (e) {
      throw FirestoreException('Get current user profile failed: ${e.message}');
    } catch (e) {
      throw FirestoreException('Unknown error getting profile: $e');
    }
  }

  @override
  Stream<ChatEntity> getChatData(String uid1, String uid2) {
    try {
      final chatID = generateChatID(uid1: uid1, uid2: uid2);
      return _chatCollection.doc(chatID).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          throw FirestoreException('Chat not found');
        }
        return snapshot.data()!;
      });
    } catch (e) {
      return Stream.error(FirestoreException('Error getting chat data: $e'));
    }
  }

  @override
  Stream<List<UserProfileEntity>> getUserProfiles() {
    try {
      final uid = _currentUserId;
      return _usersCollection
          .where('uid', isNotEqualTo: uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      return Stream.error(FirestoreException('Error getting profiles: $e'));
    }
  }

  @override
  Stream<List<UserProfileEntity>> searchUserProfiles(String query) {
    try {
      final uid = _currentUserId;
      if (query.isEmpty) {
        return _usersCollection
            .where('uid', isNotEqualTo: uid)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
      } else {
        return _usersCollection
            .where('uid', isNotEqualTo: uid)
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: query + '\uf8ff')
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    } catch (e) {
      return Stream.error(FirestoreException('Error searching profiles: $e'));
    }
  }

  @override
  Future<void> sendMessage(
      String uid1, String uid2, MessageEntity message) async {
    try {
      final chatID = generateChatID(uid1: uid1, uid2: uid2);
      await _chatCollection.doc(chatID).update({
        'messages': FieldValue.arrayUnion([message.toJson()]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreException('Send message failed: ${e.message}');
    } catch (e) {
      throw FirestoreException('Unknown error sending message: $e');
    }
  }
}
