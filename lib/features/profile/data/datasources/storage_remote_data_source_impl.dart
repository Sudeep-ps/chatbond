import 'dart:io';

import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/features/profile/data/datasources/storage_remote_data_source.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final FirebaseStorage _firebaseStorage;

  StorageRemoteDataSourceImpl(this._firebaseStorage);

  @override
  Future<String?> uploadUserProfilePicture(File file, String uid) async {
    try {
      final Reference fileRef = _firebaseStorage
          .ref('users/pfp')
          .child('$uid${p.extension(file.path)}');
      final UploadTask task = fileRef.putFile(file);
      final TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
      return null;
    } on FirebaseException catch (e) {
      throw StorageException('Upload profile picture failed: ${e.message}');
    } catch (e) {
      throw StorageException('Unknown error uploading profile picture: $e');
    }
  }

  @override
  Future<String?> uploadChatImage(File file, String chatID) async {
    try {
      final Reference fileRef = _firebaseStorage.ref('chats/$chatID').child(
          '${DateTime.now().toIso8601String()}${p.extension(file.path)}');
      final UploadTask task = fileRef.putFile(file);
      final TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
      return null;
    } on FirebaseException catch (e) {
      throw StorageException('Upload chat image failed: ${e.message}');
    } catch (e) {
      throw StorageException('Unknown error uploading chat image: $e');
    }
  }

  @override
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;
      final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw StorageException('Delete profile picture failed: ${e.message}');
    } catch (e) {
      throw StorageException('Unknown error deleting profile picture: $e');
    }
  }
}
