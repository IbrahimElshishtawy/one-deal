import 'environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
  final bool enableMockMode;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableLogging,
    required this.enableMockMode,
  });

  factory AppConfig.development() {
    return const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: 'http://localhost:3000/api/v1',
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: true,
      enableMockMode: true,
    );
  }

  factory AppConfig.staging() {
    return const AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'https://staging-api.marketspace.eg/api/v1',
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: true,
      enableMockMode: false,
    );
  }

  factory AppConfig.production() {
    const definedUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://one-deal-cjjt-production.up.railway.app/api/v1',
    );
    return const AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: definedUrl,
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: false,
      enableMockMode: false,
    );
  }

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'production');
    switch (env) {
      case 'development':
        return AppConfig.development();
      case 'staging':
        return AppConfig.staging();
      case 'production':
      default:
        return AppConfig.production();
    }
  }
}
