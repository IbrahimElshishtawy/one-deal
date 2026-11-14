import 'dart:async';

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
import '../storage/storage_keys.dart';

/// Provides the active runtime application configuration.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError(
    'appConfigProvider must be overridden in ProviderScope',
  );
});

/// Provides the structured application logger.
final appLoggerProvider = Provider<AppLogger>((ref) {
  final config = ref.watch(appConfigProvider);
  return AppLoggerImpl(isLoggingEnabled: config.enableLogging);
});

/// Provides platform network connectivity status.
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  throw UnimplementedError(
    'networkInfoProvider must be overridden in ProviderScope',
  );
});

/// Provides persistent key-value preferences.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError(
    'preferencesServiceProvider must be overridden in ProviderScope',
  );
});

/// Provides platform-backed hardware encrypted secure storage.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError(
    'secureStorageServiceProvider must be overridden in ProviderScope',
  );
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
    onSessionExpired: () {
      unawaited(ref.read(sessionProvider.notifier).logout());
    },
  );
});

/// Manages authentication session lifecycle.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState.unauthenticated();
  }

  Future<void> restoreSession() async {
    final tokens = ref.read(tokenProvider);
    final secureStorage = ref.read(secureStorageServiceProvider);
    final accessToken = await tokens.getAccessToken();
    final storedUserId = await secureStorage.read(StorageKeys.userId);

    if (accessToken != null && accessToken.isNotEmpty) {
      state = SessionState(
        status: SessionStatus.authenticated,
        userId: (storedUserId != null && storedUserId.isNotEmpty)
            ? storedUserId
            : null,
      );
    } else {
      state = const SessionState.unauthenticated();
    }
  }

  void setAuthenticated({String? userId}) {
    state = SessionState(status: SessionStatus.authenticated, userId: userId);
    if (userId != null && userId.isNotEmpty) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      unawaited(secureStorage.write(StorageKeys.userId, userId));
    }
  }

  Future<void> logout() async {
    final tokens = ref.read(tokenProvider);
    final secureStorage = ref.read(secureStorageServiceProvider);
    await tokens.clearTokens();
    await secureStorage.delete(StorageKeys.userId);
    state = const SessionState.unauthenticated();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});
