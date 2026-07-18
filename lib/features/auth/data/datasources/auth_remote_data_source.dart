import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/auth/domain/entities/verify_otp_response.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signup(String email, String password, String name);
  Future<VerifyOtpResponse?> verifyOtp(
      String email, String otp, String purpose);
  Future<void> resendOtp(String email, String purpose);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String resetToken, String password);
  Future<void> logout();
  Future<void> deleteUser();
  Stream<AuthUser?> authStateChanges();
  AuthUser? getCurrentUser();
}
