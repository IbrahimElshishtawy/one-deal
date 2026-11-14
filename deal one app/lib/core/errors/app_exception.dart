abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  const AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() =>
      '$runtimeType: $message (code: $errorCode, status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.errorCode = 'NETWORK_UNAVAILABLE',
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Connection timeout',
    super.errorCode = 'CONNECTION_TIMEOUT',
  });
}

class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.errorCode = 'SERVER_ERROR',
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication required',
    super.statusCode = 401,
    super.errorCode = 'UNAUTHORIZED',
  });
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access forbidden',
    super.statusCode = 403,
    super.errorCode = 'FORBIDDEN',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
    super.errorCode = 'NOT_FOUND',
  });
}

class ConflictException extends AppException {
  const ConflictException({
    super.message = 'Resource conflict',
    super.statusCode = 409,
    super.errorCode = 'CONFLICT',
    super.details,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.statusCode = 400,
    super.errorCode = 'VALIDATION_FAILED',
    super.details,
  });
}

class RateLimitException extends AppException {
  const RateLimitException({
    super.message = 'Rate limit exceeded',
    super.statusCode = 429,
    super.errorCode = 'RATE_LIMIT_EXCEEDED',
  });
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.errorCode = 'CACHE_ERROR',
  });
}

class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred',
    super.errorCode = 'UNKNOWN_ERROR',
    super.details,
  });
}
