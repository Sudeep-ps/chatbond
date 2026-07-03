import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? AuthUser.fromFirebaseUser(user) : null;
    });
  }

  @override
  Future<void> deleteUser() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Failed to delete user: ${e.message}');
    } catch (e) {
      throw AuthException('Unknown error deleting user: $e');
    }
  }

  @override
  AuthUser? getCurrentUser() {
    final user = _firebaseAuth.currentUser;
    return user != null ? AuthUser.fromFirebaseUser(user) : null;
  }

  @override
  Future<AuthUser> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return AuthUser.fromFirebaseUser(credential.user!);
      }
      throw AuthException('Login failed: No user returned');
    } on FirebaseAuthException catch (e) {
      throw AuthException('Login failed: ${e.message}');
    } catch (e) {
      throw AuthException('Unknown error during login: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException('Logout failed: ${e.message}');
    } catch (e) {
      throw AuthException('Unknown error during logout: $e');
    }
  }

  @override
  Future<AuthUser> signup(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return AuthUser.fromFirebaseUser(credential.user!);
      }
      throw AuthException('Signup failed: No user returned');
    } on FirebaseAuthException catch (e) {
      throw AuthException('Signup failed: ${e.message}');
    } catch (e) {
      throw AuthException('Unknown error during signup: $e');
    }
  }
}
