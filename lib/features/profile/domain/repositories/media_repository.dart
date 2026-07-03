import 'dart:io';

abstract class MediaRepository {
  Future<File?> getImageFromGallery();
}
