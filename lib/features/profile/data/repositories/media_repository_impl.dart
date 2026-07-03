import 'dart:io';

import 'package:chatbond/features/profile/data/datasources/media_local_data_source.dart';
import 'package:chatbond/features/profile/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaLocalDataSource _localDataSource;

  MediaRepositoryImpl(this._localDataSource);

  @override
  Future<File?> getImageFromGallery() {
    return _localDataSource.getImageFromGallery();
  }
}
