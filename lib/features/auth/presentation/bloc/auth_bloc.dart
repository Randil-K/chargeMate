import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/auth/domain/entities/user.dart';
import 'package:charge_mate/features/auth/domain/usecases/auth_usecases.dart';

// ═════════════════════════════════ EVENTS ═════════════════════════════
sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Fired at startup to restore a persisted session.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  const RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [fullName, email, phone, password];
}

class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested(this.email);
  @override
  List<Object?> get props => [email];
}

class ProfileUpdated extends AuthEvent {
  final User user;
  const ProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}

// ═════════════════════════════════ STATE ══════════════════════════════
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? errorMessage;
  final bool resetEmailSent;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.resetEmailSent = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool? resetEmailSent,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        resetEmailSent: resetEmailSent ?? this.resetEmailSent,
      );

  @override
  List<Object?> get props =>
      [status, user, isSubmitting, errorMessage, resetEmailSent];
}

// ═════════════════════════════════ BLOC ═══════════════════════════════
/// App-wide session BLoC. The router listens to it to guard routes.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;
  final RequestPasswordResetUseCase _resetPassword;
  final UpdateProfileUseCase _updateProfile;

  AuthBloc({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
    required RequestPasswordResetUseCase resetPassword,
    required UpdateProfileUseCase updateProfile,
  })  : _login = login,
        _register = register,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _resetPassword = resetPassword,
        _updateProfile = updateProfile,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheck);
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<PasswordResetRequested>(_onReset);
    on<ProfileUpdated>(_onProfileUpdated);
    on<LogoutRequested>(_onLogout);
    on<AuthErrorCleared>(
      (_, emit) => emit(state.copyWith(clearError: true, resetEmailSent: false)),
    );
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
      (user) => emit(user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onLogin(LoginSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result =
        await _login(LoginParams(email: e.email, password: e.password));
    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, errorMessage: f.message)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onRegister(
      RegisterSubmitted e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _register(RegisterParams(
      fullName: e.fullName,
      email: e.email,
      phone: e.phone,
      password: e.password,
    ));
    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, errorMessage: f.message)),
      (user) => emit(AuthState(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onReset(
      PasswordResetRequested e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _resetPassword(e.email);
    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isSubmitting: false, resetEmailSent: true)),
    );
  }

  Future<void> _onProfileUpdated(
      ProfileUpdated e, Emitter<AuthState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final result = await _updateProfile(e.user);
    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, errorMessage: f.message)),
      (user) => emit(state.copyWith(isSubmitting: false, user: user)),
    );
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await _logout(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
