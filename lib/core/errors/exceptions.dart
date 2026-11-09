// ChargeMate — Core Exception Types
//
// Exceptions are thrown by data sources, then caught by repositories
// and converted into Failure types.

/// Thrown when the server returns an error response.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    this.message = 'Server error occurred.',
    this.statusCode,
  });

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when there is no internet connection.
class NetworkException implements Exception {
  final String message;

  const NetworkException({
    this.message = 'No internet connection.',
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when local cache operations fail.
class CacheException implements Exception {
  final String message;

  const CacheException({
    this.message = 'Cache operation failed.',
  });

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when authentication fails (401, invalid token, etc.)
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException({
    this.message = 'Authentication error.',
    this.statusCode,
  });

  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Thrown when a requested resource is not found.
class NotFoundException implements Exception {
  final String message;

  const NotFoundException({
    this.message = 'Resource not found.',
  });

  @override
  String toString() => 'NotFoundException: $message';
}
