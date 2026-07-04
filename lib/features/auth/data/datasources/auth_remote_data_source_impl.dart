import 'dart:convert';
import 'package:chatbond/core/exceptions/exceptions.dart';
import 'package:chatbond/core/network/api_client.dart';
import 'package:chatbond/core/storage/auth_session.dart';
import 'package:chatbond/core/storage/token_storage.dart';
import 'package:chatbond/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
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
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      throw AuthException(
          e.response?.data['message']?.toString() ?? 'Signup failed');
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
