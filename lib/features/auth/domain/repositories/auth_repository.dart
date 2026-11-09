import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/auth/domain/entities/user.dart';

/// Contract for authentication & profile operations.
///
/// The domain layer depends only on this abstraction; the data layer
/// decides whether it talks to the Spring Boot API or the mock backend.
abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();

  /// Returns the signed-in user from a persisted session, or `null`.
  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, Unit>> requestPasswordReset(String email);

  Future<Either<Failure, User>> updateProfile(User user);
}
