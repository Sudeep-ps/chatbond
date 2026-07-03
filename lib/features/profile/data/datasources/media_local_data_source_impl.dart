import 'dart:io';

import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/features/profile/data/datasources/media_local_data_source.dart';
import 'package:image_picker/image_picker.dart';

class MediaLocalDataSourceImpl implements MediaLocalDataSource {
  final ImagePicker _picker;

  MediaLocalDataSourceImpl(this._picker);

  @override
  Future<File?> getImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        return File(file.path);
      }
      return null;
    } catch (e) {
      throw MediaException('Failed to pick image: $e');
    }
  }
}
