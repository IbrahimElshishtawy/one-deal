import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../security/secure_token_provider.dart';
import '../security/session_state.dart';
import '../security/token_provider.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

/// Provides the active runtime application configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden in ProviderScope');
});

/// Provides the structured application logger.
final appLoggerProvider = Provider<AppLogger>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppLoggerImpl(isLoggingEnabled: config.enableLogging);
});

/// Provides platform network connectivity status.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  throw UnimplementedError('networkInfoProvider must be overridden in ProviderScope');
});

/// Provides persistent key-value preferences.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('preferencesServiceProvider must be overridden in ProviderScope');
});

/// Provides platform-backed hardware encrypted secure storage.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError('secureStorageServiceProvider must be overridden in ProviderScope');
});

/// Provides token access and mutation interface.
final tokenProvider = Provider<TokenProvider>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return SecureTokenProvider(secureStorageService: secureStorage);
});

/// Provides the centrally configured Dio API HTTP client.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final token = ref.watch(tokenProvider);
  final logger = ref.watch(appLoggerProvider);

  return DioApiClient.create(
    appConfig: config,
    networkInfo: networkInfo,
    tokenProvider: token,
    logger: logger,
  );
});

/// Manages authentication session lifecycle.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState.unauthenticated();
  }

  Future<void> restoreSession() async {
    state = const SessionState.authenticating();
    final tokens = ref.read(tokenProvider);
    final accessToken = await tokens.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      state = const SessionState.authenticated();
    } else {
      state = const SessionState.unauthenticated();
    }
  }

  Future<void> setAuthenticated() async {
    state = const SessionState.authenticated();
  }

  Future<void> logout() async {
    final tokens = ref.read(tokenProvider);
    await tokens.clearTokens();
    state = const SessionState.unauthenticated();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
