import 'package:chatbond/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/auth/domain/repositories/auth_repository.dart';

import '../../domain/entities/verify_otp_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }

  @override
  Future<void> deleteUser() {
    return _remoteDataSource.deleteUser();
  }

  @override
  AuthUser? getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Future<AuthUser> login(String email, String password) {
    return _remoteDataSource.login(email, password);
  }

  @override
  Future<void> logout() {
    return _remoteDataSource.logout();
  }

  @override
  Future<AuthUser> signup(String email, String password, String name) {
    return _remoteDataSource.signup(email, password, name);
  }

  @override
  Future<VerifyOtpResponse?> verifyOtp(
      String email, String otp, String purpose) {
    return _remoteDataSource.verifyOtp(email, otp, purpose);
  }

  @override
  Future<void> resendOtp(String email, String purpose) {
    return _remoteDataSource.resendOtp(email, purpose);
  }

  @override
  Future<void> forgotPassword(String email) {
    return _remoteDataSource.forgotPassword(email);
  }

  @override
  Future<void> resetPassword(String resetToken, String password) {
    return _remoteDataSource.resetPassword(resetToken, password);
  }
}
