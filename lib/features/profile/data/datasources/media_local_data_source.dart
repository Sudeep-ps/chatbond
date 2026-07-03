import 'dart:io';

abstract class MediaLocalDataSource {
  Future<File?> getImageFromGallery();
}
