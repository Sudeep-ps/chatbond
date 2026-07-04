import 'dart:io';
import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/core/network/api_client.dart';
import 'package:chatbond/features/profile/data/datasources/storage_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final ApiClient _apiClient;

  StorageRemoteDataSourceImpl(this._apiClient);

  Future<String?> _uploadAndGetUrl(File file, String type) async {
    try {
      final ext = p.extension(file.path);
      final presign = await _apiClient.dio
          .post('/storage/presign', data: {'ext': ext, 'type': type});
      final uploadUrl = presign.data['uploadUrl'] as String;
      final key = presign.data['key'] as String;

      final plainDio =
          Dio(); // no auth header needed for the presigned S3 PUT itself
      await plainDio.put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {'Content-Length': await file.length()},
        ),
      );

      final viewUrl =
          await _apiClient.dio.post('/storage/view-url', data: {'key': key});
      return viewUrl.data as String;
    } on DioException catch (e) {
      throw StorageException(
          e.response?.data['message']?.toString() ?? 'Upload failed');
    }
  }

  @override
  Future<String?> uploadUserProfilePicture(File file, String uid) =>
      _uploadAndGetUrl(file, 'pfp');

  @override
  Future<String?> uploadChatImage(File file, String chatID) =>
      _uploadAndGetUrl(file, 'chat');

  @override
  Future<void> deleteProfilePicture(String imageUrl) async {
    // no delete endpoint exists on the backend yet — add a DELETE /storage route there first if you need this
  }
}
