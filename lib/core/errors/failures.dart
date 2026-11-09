// ChargeMate — Core Error Types
//
// Uses `dartz` Either<Failure, T> pattern for type-safe error handling.
import 'package:equatable/equatable.dart';

/// Base failure class for all domain-level errors.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server/API failure.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'An unexpected server error occurred.',
    super.statusCode,
  });
}

/// Network connectivity failure.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

/// Local storage/cache failure.
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to access local storage.',
  });
}

/// Authentication failure (invalid credentials, expired token, etc.)
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please sign in again.',
    super.statusCode,
  });
}

/// Validation failure (invalid input data).
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    super.message = 'Invalid input data.',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Location/GPS failure.
class LocationFailure extends Failure {
  const LocationFailure({
    super.message = 'Unable to determine your location.',
  });
}

/// Permission denied failure.
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Required permission was denied.',
  });
}

/// Not found failure.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
  });
}
