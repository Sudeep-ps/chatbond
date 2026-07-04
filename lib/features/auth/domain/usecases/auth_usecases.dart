import 'package:chatbond/features/auth/domain/entities/auth_user.dart';
import 'package:chatbond/features/auth/domain/repositories/auth_repository.dart';

class LoginUsecase {
  final AuthRepository repository;

  LoginUsecase(this.repository);

  Future<AuthUser> call(String email, String password) {
    return repository.login(email, password);
  }
}

class SignupUsecase {
  final AuthRepository repository;
  SignupUsecase(this.repository);

  Future<AuthUser> call(String email, String password, String name) {
    return repository.signup(email, password, name);
  }
}

class LogoutUsecase {
  final AuthRepository repository;

  LogoutUsecase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

class DeleteUserUsecase {
  final AuthRepository repository;

  DeleteUserUsecase(this.repository);

  Future<void> call() {
    return repository.deleteUser();
  }
}

class GetCurrentUserUsecase {
  final AuthRepository repository;

  GetCurrentUserUsecase(this.repository);

  AuthUser? call() {
    return repository.getCurrentUser();
  }
}

class AuthStateChangesUsecase {
  final AuthRepository repository;

  AuthStateChangesUsecase(this.repository);

  Stream<AuthUser?> call() {
    return repository.authStateChanges();
  }
}
