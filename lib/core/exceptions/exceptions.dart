abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class FirestoreException extends AppException {
  const FirestoreException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message);
}

class MediaException extends AppException {
  const MediaException(super.message);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}
