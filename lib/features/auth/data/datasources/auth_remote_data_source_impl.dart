import 'dart:convert';
import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/core/network/api_client.dart';
import 'package:chatbond/core/storage/auth_session.dart';
import 'package:chatbond/core/storage/token_storage.dart';
import 'package:chatbond/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/auth/domain/entities/verify_otp_response.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  // call once at app startup, before runApp, to restore a cached session
  static Future<void> bootstrap() async {
    final userJson = await TokenStorage.getUserJson();
    final accessToken = await TokenStorage.getAccessToken();
    if (userJson != null && accessToken != null) {
      AuthSession.currentUser = AuthUser.fromJson(jsonDecode(userJson));
    }
  }

  Future<AuthUser> _handleAuthResponse(Response response) async {
    final data = response.data;
    final user = AuthUser.fromJson(data['user']);
    await TokenStorage.saveTokens(data['accessToken'], data['refreshToken']);
    await TokenStorage.saveUserJson(jsonEncode(data['user']));
    AuthSession.update(user);
    return user;
  }

  @override
  Future<AuthUser> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Login failed');
    }
  }

  @override
  Future<AuthUser> signup(String email, String password, String name) async {
    try {
      await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      return AuthUser(uid: '', email: email, name: name, isVerified: false);
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Signup failed');
    }
  }

  @override
  @override
  Future<VerifyOtpResponse> verifyOtp(
    String email,
    String otp,
    String purpose,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'email': email,
          'otp': otp,
          'purpose': purpose,
        },
      );

      print(response.data);

      if (purpose == 'SIGNUP') {
        final user = await _handleAuthResponse(response);

        return VerifyOtpResponse(
          user: user,
        );
      }

      // RESET_PASSWORD
      return VerifyOtpResponse(
        resetToken: response.data['resetToken'],
      );
    } on DioException catch (e) {
      throw AuthException(
        e.response?.data['message']?.toString() ?? 'OTP verification failed',
      );
    }
  }

  @override
  Future<void> resendOtp(String email, String purpose) async {
    try {
      await _apiClient.dio
          .post('/auth/resend-otp', data: {'email': email, 'purpose': purpose});
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Resending OTP failed');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio
          .post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Forgot password failed');
    }
  }

  @override
  Future<void> resetPassword(String resetToken, String password) async {
    try {
      await _apiClient.dio.post('/auth/reset-password', data: {
        'resetToken': resetToken,
        'password': password,
      });
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Password reset failed');
    }
  }

  @override
  Future<void> logout() async {
    await TokenStorage.clear();
    AuthSession.update(null);
  }

  @override
  Future<void> deleteUser() async {
    // no DELETE /users/me endpoint exists on the backend yet — add one there first
    throw AuthException('Account deletion isn\'t supported by the server yet');
  }

  @override
  AuthUser? getCurrentUser() => AuthSession.currentUser;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield AuthSession.currentUser;
    yield* AuthSession.changes;
  }
}
