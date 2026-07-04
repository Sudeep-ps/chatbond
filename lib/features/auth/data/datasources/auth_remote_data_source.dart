import 'package:chatbond/features/auth/domain/entities/auth_user.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signup(String email, String password, String name);
  Future<void> logout();
  Future<void> deleteUser();
  Stream<AuthUser?> authStateChanges();
  AuthUser? getCurrentUser();
}
