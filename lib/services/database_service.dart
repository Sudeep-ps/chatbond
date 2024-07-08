import 'package:chatbond/models/chat.dart';
import 'package:chatbond/models/message.dart';
import 'package:chatbond/models/user_profile.dart';
import 'package:chatbond/services/auth_service.dart';
import 'package:chatbond/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class DatabaseService {
  final GetIt _getIt = GetIt.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  late AuthService _authService;

  CollectionReference? _usersCollection;
  CollectionReference? _chatCollection;

  DatabaseService() {
    _authService = _getIt.get<AuthService>();
    _setupCollectionReferences();
  }

  void _setupCollectionReferences() {
    _usersCollection = _firebaseFirestore
        .collection('users')
        .withConverter<UserProfile>(
            fromFirestore: (snapshots, _) =>
                UserProfile.fromJson(snapshots.data()!),
            toFirestore: (userProfile, _) => userProfile.toJson());
    _chatCollection = _firebaseFirestore
        .collection('chats')
        .withConverter<Chat>(
            fromFirestore: (snapshots, _) => Chat.fromJson(snapshots.data()!),
            toFirestore: (chat, _) => chat.toJson());
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    await _usersCollection?.doc(userProfile.uid).set(userProfile);
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfilessearch(
      {String query = ''}) {
    final ref =
        _firebaseFirestore.collection('users').withConverter<UserProfile>(
              fromFirestore: (snapshot, options) =>
                  UserProfile.fromFirestore(snapshot),
              toFirestore: (userProfile, options) => userProfile.toFirestore(),
            );

    if (query.isEmpty) {
      return ref.where("uid", isNotEqualTo: _authService.user!.uid).snapshots();
    } else {
      return ref
          .where("uid", isNotEqualTo: _authService.user!.uid)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .snapshots();
    }
  }

  Stream<QuerySnapshot<UserProfile>> getUserProfiles() {
    return _usersCollection
        ?.where("uid", isNotEqualTo: _authService.user!.uid)
        .snapshots() as Stream<QuerySnapshot<UserProfile>>;
  }

  Future<bool> checkChatExist(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final result = await _chatCollection?.doc(chatID).get();
    if (result != null) {
      return result.exists;
    }
    return false;
  }

  Future<void> createNewChat(String uid1, String uid2) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);
    final chat = Chat(id: chatID, participants: [uid1, uid2], messages: []);
    await docRef.set(chat);
  }

  Future<void> sendChatMessage(
      String uid1, String uid2, Message message) async {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    final docRef = _chatCollection!.doc(chatID);
    await docRef.update({
      "messages": FieldValue.arrayUnion([message.toJson()]),
    });
  }

  Stream<DocumentSnapshot<Chat>> getChatData(String uid1, String uid2) {
    String chatID = generateChatID(uid1: uid1, uid2: uid2);
    return _chatCollection?.doc(chatID).snapshots()
        as Stream<DocumentSnapshot<Chat>>;
  }

  Future<UserProfile> getCurrentUserProfile() async {
    String uid = _authService.user!.uid;
    DocumentSnapshot<UserProfile> snapshot =
        await _usersCollection!.doc(uid).get() as DocumentSnapshot<UserProfile>;
    return snapshot.data()!;
  }

  Future<void> updateUserProfilePicture(
    String? imageUrl,
  ) async {
    String uid = _authService.user!.uid;
    await _usersCollection!.doc(uid).update({'pfpURL': imageUrl});
  }

  Future<void> clearChat(String chatID) async {
    final docRef = _chatCollection!.doc(chatID);
    await docRef.update({'messages': []});
  }

  Future<void> deleteUserData(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    } catch (e) {
      print("Error deleting user data: $e");
      throw e; // Handle the error as per your app's requirements
    }
  }

  Future<void> deleteChats(String uid) async {
    try {
      // Fetch all chat documents where the chatId contains the user's uid
      QuerySnapshot snapshot = await _firebaseFirestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();

      // Iterate over each document and delete it
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error deleting chats: $e");
      throw e; // Handle the error as per your app's requirements
    }
  }
}
