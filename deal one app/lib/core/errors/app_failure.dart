abstract class AppFailure {
  final String userFriendlyMessage;
  final String? technicalCode;

  const AppFailure({required this.userFriendlyMessage, this.technicalCode});

  @override
  String toString() => '$runtimeType: $userFriendlyMessage ($technicalCode)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.userFriendlyMessage =
        'No internet connection. Please verify your network.',
    super.technicalCode = 'NETWORK_ERROR',
  });
}

class TimeoutFailure extends AppFailure {
  const TimeoutFailure({
    super.userFriendlyMessage = 'The connection timed out. Please try again.',
    super.technicalCode = 'TIMEOUT_ERROR',
  });
}

class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.userFriendlyMessage,
    super.technicalCode = 'SERVER_ERROR',
  });
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({
    super.userFriendlyMessage =
        'Your session has expired. Please log in again.',
    super.technicalCode = 'UNAUTHORIZED',
  });
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({
    super.userFriendlyMessage =
        'You do not have permission to perform this action.',
    super.technicalCode = 'FORBIDDEN',
  });
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.userFriendlyMessage = 'The requested item could not be found.',
    super.technicalCode = 'NOT_FOUND',
  });
}

class ValidationFailure extends AppFailure {
  final Map<String, String> fieldErrors;

  const ValidationFailure({
    required super.userFriendlyMessage,
    super.technicalCode = 'VALIDATION_ERROR',
    this.fieldErrors = const {},
  });
}

class RateLimitFailure extends AppFailure {
  const RateLimitFailure({
    super.userFriendlyMessage =
        'Too many requests. Please wait a moment and try again.',
    super.technicalCode = 'RATE_LIMIT_ERROR',
  });
}

class ConflictFailure extends AppFailure {
  const ConflictFailure({
    required super.userFriendlyMessage,
    super.technicalCode = 'CONFLICT',
  });
}

class CacheFailure extends AppFailure {
  const CacheFailure({
    required super.userFriendlyMessage,
    super.technicalCode = 'CACHE_ERROR',
  });
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.userFriendlyMessage = 'Something went wrong. Please try again.',
    super.technicalCode = 'UNKNOWN_ERROR',
  });
}
