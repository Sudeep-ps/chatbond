import 'dart:async';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';

class AuthSession {
  static AuthUser? currentUser;
  static final _controller = StreamController<AuthUser?>.broadcast();

  static void update(AuthUser? user) {
    currentUser = user;
    _controller.add(user);
  }

  static Stream<AuthUser?> get changes => _controller.stream;
}
