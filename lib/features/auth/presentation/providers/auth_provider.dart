import 'package:chatbond/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:chatbond/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/auth/domain/entities/verify_otp_response.dart';
import 'package:chatbond/features/auth/domain/repositories/auth_repository.dart';
import 'package:chatbond/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient);
});

// Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// Use Cases Providers
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUsecase(repository);
});

final signupUsecaseProvider = Provider<SignupUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignupUsecase(repository);
});

final verifyOtpUsecaseProvider = Provider<VerifyOtpUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyOtpUsecase(repository);
});

final resendOtpUsecaseProvider = Provider<ResendOtpUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResendOtpUsecase(repository);
});

final forgotPasswordUsecaseProvider = Provider<ForgotPasswordUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordUsecase(repository);
});

final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUsecase(repository);
});

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUsecase(repository);
});

final deleteUserUsecaseProvider = Provider<DeleteUserUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return DeleteUserUsecase(repository);
});

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUsecase(repository);
});

final authStateChangesUsecaseProvider =
    Provider<AuthStateChangesUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateChangesUsecase(repository);
});

// State Notifiers and Providers
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final usecase = ref.watch(authStateChangesUsecaseProvider);
  return usecase();
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  final usecase = ref.watch(getCurrentUserUsecaseProvider);
  return usecase();
});

// Login State Notifier
class LoginNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  LoginNotifier(this._loginUsecase) : super(const AsyncValue.data(null));
  final LoginUsecase _loginUsecase;

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loginUsecase(email, password));
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final loginProvider =
    StateNotifierProvider<LoginNotifier, AsyncValue<AuthUser?>>((ref) {
  final usecase = ref.watch(loginUsecaseProvider);
  return LoginNotifier(usecase);
});

// Signup State Notifier
class SignupNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  SignupNotifier(this._signupUsecase) : super(const AsyncValue.data(null));
  final SignupUsecase _signupUsecase;

  Future<void> signup(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _signupUsecase(email, password, name));
  }
}

final signupProvider =
    StateNotifierProvider<SignupNotifier, AsyncValue<AuthUser?>>((ref) {
  final usecase = ref.watch(signupUsecaseProvider);
  return SignupNotifier(usecase);
});

class VerifyOtpNotifier extends StateNotifier<AsyncValue<VerifyOtpResponse?>> {
  VerifyOtpNotifier(this._verifyOtpUsecase)
      : super(const AsyncValue.data(null));
  final VerifyOtpUsecase _verifyOtpUsecase;

  Future<void> verifyOtp(String email, String otp, String purpose) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _verifyOtpUsecase(email, otp, purpose));
  }
}

final verifyOtpProvider =
    StateNotifierProvider<VerifyOtpNotifier, AsyncValue<VerifyOtpResponse?>>(
        (ref) {
  final usecase = ref.watch(verifyOtpUsecaseProvider);
  return VerifyOtpNotifier(usecase);
});

class ResendOtpNotifier extends StateNotifier<AsyncValue<void>> {
  ResendOtpNotifier(this._resendOtpUsecase)
      : super(const AsyncValue.data(null));
  final ResendOtpUsecase _resendOtpUsecase;

  Future<void> resendOtp(String email, String purpose) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _resendOtpUsecase(email, purpose));
  }
}

final resendOtpProvider =
    StateNotifierProvider<ResendOtpNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(resendOtpUsecaseProvider);
  return ResendOtpNotifier(usecase);
});

class ForgotPasswordNotifier extends StateNotifier<AsyncValue<void>> {
  ForgotPasswordNotifier(this._forgotPasswordUsecase)
      : super(const AsyncValue.data(null));
  final ForgotPasswordUsecase _forgotPasswordUsecase;

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _forgotPasswordUsecase(email));
  }
}

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(forgotPasswordUsecaseProvider);
  return ForgotPasswordNotifier(usecase);
});

class ResetPasswordNotifier extends StateNotifier<AsyncValue<void>> {
  ResetPasswordNotifier(this._resetPasswordUsecase)
      : super(const AsyncValue.data(null));
  final ResetPasswordUsecase _resetPasswordUsecase;

  Future<void> resetPassword(String resetToken, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _resetPasswordUsecase(resetToken, password));
  }
}

final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(resetPasswordUsecaseProvider);
  return ResetPasswordNotifier(usecase);
});

// Logout State Notifier
// class LogoutNotifier extends StateNotifier<AsyncValue<void>> {
//   LogoutNotifier(this._logoutUsecase) : super(const AsyncValue.data(null));
//   final LogoutUsecase _logoutUsecase;

//   Future<void> logout() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => _logoutUsecase());
//   }

//   void reset() {
//     state = const AsyncValue.data(null);
//   }
// }

// final logoutProvider =
//     StateNotifierProvider<LogoutNotifier, AsyncValue<void>>((ref) {
//   final usecase = ref.watch(logoutUsecaseProvider);
//   return LogoutNotifier(usecase);
// });

// Delete User State Notifier
class DeleteUserNotifier extends StateNotifier<AsyncValue<void>> {
  DeleteUserNotifier(this._deleteUserUsecase)
      : super(const AsyncValue.data(null));
  final DeleteUserUsecase _deleteUserUsecase;

  Future<void> deleteUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _deleteUserUsecase());
  }
}

final deleteUserProvider =
    StateNotifierProvider<DeleteUserNotifier, AsyncValue<void>>((ref) {
  final usecase = ref.watch(deleteUserUsecaseProvider);
  return DeleteUserNotifier(usecase);
});
