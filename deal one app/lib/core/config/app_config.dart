import 'package:flutter/foundation.dart';

import 'package:market_space/core/config/environment.dart';

class AppConfig {
  static const String defaultProductionApiBaseUrl =
      'https://one-deal-cjjt-production.up.railway.app/api/v1';
  static const String defaultLocalDevApiBaseUrl =
      'http://127.0.0.1:3000/api/v1';

  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
  final bool enableMockMode;

  /// Enables automatic Development Guest backend session (`POST /auth/dev-guest`).
  /// Strictly fail-closed (always false) in production.
  final bool enableDevGuestAuth;

  /// Launches directly on the Home Hub without gating on Onboarding/Login.
  final bool startOnHome;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableLogging,
    required this.enableMockMode,
    bool enableDevGuestAuth = false,
    this.startOnHome = true,
  }) : enableDevGuestAuth =
           environment == AppEnvironment.production ? false : enableDevGuestAuth;

  factory AppConfig.development() {
    return const AppConfig(
      environment: AppEnvironment.development,
      apiBaseUrl: defaultLocalDevApiBaseUrl,
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      enableLogging: true,
      enableMockMode: false,
      // Opt-in only: run with --dart-define=ENABLE_DEV_GUEST_AUTH=true to skip login.
      enableDevGuestAuth: bool.fromEnvironment('ENABLE_DEV_GUEST_AUTH'),
      startOnHome: false,
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
      enableDevGuestAuth: false,
      startOnHome: false,
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
      enableDevGuestAuth: false,
      startOnHome: false,
    );
  }

  factory AppConfig.fromEnvironment() {
    const rawEnvName = String.fromEnvironment('APP_ENV');
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');

    // Fail-closed: release builds always default to production unless explicitly overridden.
    final resolvedEnv = rawEnvName.trim().isNotEmpty
        ? rawEnvName.trim()
        : (kReleaseMode ? 'production' : 'development');

    final baseConfig = switch (resolvedEnv) {
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
      enableDevGuestAuth: baseConfig.enableDevGuestAuth,
      startOnHome: baseConfig.startOnHome,
    );
  }
}
