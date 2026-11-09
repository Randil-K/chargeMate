import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/auth/domain/entities/user.dart';
import 'package:charge_mate/features/auth/domain/repositories/auth_repository.dart';

// ── Login ─────────────────────────────────────────────────────────────
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) => _repository.login(
        email: params.email.trim().toLowerCase(),
        password: params.password,
      );
}

// ── Register ──────────────────────────────────────────────────────────
class RegisterParams extends Equatable {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const RegisterParams({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, phone, password];
}

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) =>
      _repository.register(
        fullName: params.fullName.trim(),
        email: params.email.trim().toLowerCase(),
        phone: params.phone.trim(),
        password: params.password,
      );
}

// ── Logout ────────────────────────────────────────────────────────────
class LogoutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}

// ── Current user (session restore) ────────────────────────────────────
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) =>
      _repository.getCurrentUser();
}

// ── Password reset ────────────────────────────────────────────────────
class RequestPasswordResetUseCase implements UseCase<Unit, String> {
  final AuthRepository _repository;
  const RequestPasswordResetUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repository.requestPasswordReset(email.trim().toLowerCase());
}

// ── Update profile ────────────────────────────────────────────────────
class UpdateProfileUseCase implements UseCase<User, User> {
  final AuthRepository _repository;
  const UpdateProfileUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(User user) =>
      _repository.updateProfile(user);
}
