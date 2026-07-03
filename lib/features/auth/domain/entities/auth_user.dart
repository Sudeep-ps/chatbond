import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  final String uid;
  final String? email;

  AuthUser({
    required this.uid,
    required this.email,
  });

  factory AuthUser.fromFirebaseUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
    );
  }
}
