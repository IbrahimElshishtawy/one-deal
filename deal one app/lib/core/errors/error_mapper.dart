import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'app_failure.dart';

class ErrorMapper {
  static AppFailure map(Object error) {
    if (error is AppFailure) {
      return error;
    }

    if (error is AppException) {
      return _mapAppException(error);
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    return UnknownFailure(
      userFriendlyMessage: error.toString(),
      technicalCode: 'UNEXPECTED_EXCEPTION',
    );
  }

  static AppFailure _mapAppException(AppException exception) {
    switch (exception) {
      case NetworkException():
        return NetworkFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case TimeoutException():
        return TimeoutFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case UnauthorizedException():
        return UnauthorizedFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case ForbiddenException():
        return ForbiddenFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case NotFoundException():
        return NotFoundFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case ConflictException():
        return ConflictFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case RateLimitException():
        return RateLimitFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case ValidationException():
        final Map<String, String> fieldErrors = {};
        if (exception.details is List) {
          for (final item in exception.details as List) {
            if (item is Map &&
                item.containsKey('field') &&
                item.containsKey('issue')) {
              fieldErrors[item['field'].toString()] = item['issue'].toString();
            }
          }
        }
        return ValidationFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
          fieldErrors: fieldErrors,
        );
      case CacheException():
        return CacheFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case ServerException():
        return ServerFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      case UnknownException():
        return UnknownFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
      default:
        return UnknownFailure(
          userFriendlyMessage: exception.message,
          technicalCode: exception.errorCode,
        );
    }
  }

  static AppFailure _mapDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const TimeoutFailure();

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      case DioExceptionType.cancel:
        return const UnknownFailure(
          userFriendlyMessage: 'The request was cancelled.',
          technicalCode: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.badResponse:
        return _mapBadResponse(dioException.response);

      case DioExceptionType.badCertificate:
        return const ServerFailure(
          userFriendlyMessage: 'Security certificate verification failed.',
          technicalCode: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        return const NetworkFailure();
    }
  }

  static AppFailure _mapBadResponse(Response<dynamic>? response) {
    if (response == null) {
      return const ServerFailure(
        userFriendlyMessage: 'Server returned an empty response.',
      );
    }

    final int statusCode = response.statusCode ?? 500;
    String extractedMessage = 'Server error occurred.';
    String? extractedCode;
    final Map<String, String> extractedFieldErrors = {};

    final dynamic data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
        final errorMap = data['error'] as Map<String, dynamic>;
        extractedMessage = errorMap['message']?.toString() ?? extractedMessage;
        extractedCode = errorMap['code']?.toString();
        if (errorMap['details'] is List) {
          for (final item in errorMap['details'] as List) {
            if (item is Map &&
                item.containsKey('field') &&
                item.containsKey('issue')) {
              extractedFieldErrors[item['field'].toString()] = item['issue']
                  .toString();
            }
          }
        }
      } else if (data.containsKey('message')) {
        extractedMessage = data['message'].toString();
      }
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ValidationFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ??
              (statusCode == 422 ? 'UNPROCESSABLE_ENTITY' : 'BAD_REQUEST'),
          fieldErrors: extractedFieldErrors,
        );
      case 401:
        return UnauthorizedFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'UNAUTHORIZED',
        );
      case 403:
        return ForbiddenFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'FORBIDDEN',
        );
      case 404:
        return NotFoundFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'NOT_FOUND',
        );
      case 409:
        return ConflictFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'CONFLICT',
        );
      case 429:
        return RateLimitFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'RATE_LIMIT_EXCEEDED',
        );
      case >= 500:
        return ServerFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'SERVER_ERROR',
        );
      default:
        return UnknownFailure(
          userFriendlyMessage: extractedMessage,
          technicalCode: extractedCode ?? 'HTTP_$statusCode',
        );
    }
  }
}
