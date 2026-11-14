import 'environment.dart';

class AppConfig {
  static const String defaultProductionApiBaseUrl =
      'https://one-deal-cjjt-production.up.railway.app/api/v1';

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
      enableMockMode: false,
    );
  }

  factory AppConfig.staging() {
    return const AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: defaultProductionApiBaseUrl,
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: true,
      enableMockMode: false,
    );
  }

  factory AppConfig.production() {
    return const AppConfig(
      environment: AppEnvironment.production,
      apiBaseUrl: defaultProductionApiBaseUrl,
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: false,
      enableMockMode: false,
    );
  }

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    );
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');

    final baseConfig = switch (envName) {
      'development' => AppConfig.development(),
      'staging' => AppConfig.staging(),
      _ => AppConfig.production(),
    };

    if (customBaseUrl.trim().isEmpty) {
      return baseConfig;
    }

    return AppConfig(
      environment: baseConfig.environment,
      apiBaseUrl: customBaseUrl.trim(),
      connectTimeout: baseConfig.connectTimeout,
      receiveTimeout: baseConfig.receiveTimeout,
      enableLogging: baseConfig.enableLogging,
      enableMockMode: false,
    );
  }
}
