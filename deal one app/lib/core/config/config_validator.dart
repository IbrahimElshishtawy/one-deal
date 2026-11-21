import 'package:market_space/core/config/app_config.dart';

class ConfigValidator {
  static void validate(AppConfig config) {
    if (config.apiBaseUrl.trim().isEmpty) {
      throw ArgumentError('Configuration error: apiBaseUrl cannot be empty.');
    }

    final parsedUri = Uri.tryParse(config.apiBaseUrl);
    final isValidHttpScheme =
        parsedUri != null &&
        (parsedUri.scheme == 'http' || parsedUri.scheme == 'https') &&
        parsedUri.host.isNotEmpty;

    if (!isValidHttpScheme) {
      throw ArgumentError(
        'Configuration error: apiBaseUrl must be a valid HTTP or HTTPS URI. Received: ${config.apiBaseUrl}',
      );
    }

    if (config.connectTimeout.inMilliseconds <= 0) {
      throw ArgumentError(
        'Configuration error: connectTimeout must be greater than zero.',
      );
    }

    if (config.receiveTimeout.inMilliseconds <= 0) {
      throw ArgumentError(
        'Configuration error: receiveTimeout must be greater than zero.',
      );
    }
  }
}
