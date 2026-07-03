import 'package:chatbond/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signup(String email, String password);
  Future<void> logout();
  Future<void> deleteUser();
  Stream<AuthUser?> authStateChanges();
  AuthUser? getCurrentUser();
}
