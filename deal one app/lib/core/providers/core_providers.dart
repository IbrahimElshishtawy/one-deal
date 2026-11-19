import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../errors/error_mapper.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
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

/// Optional backend session validator invoked during [SessionNotifier.restoreSession].
/// Returns the verified user ID if valid, or throws on unauthorized/network error.
final sessionValidatorProvider = Provider<Future<String?> Function()?>((ref) {
  return null;
});

/// Live session validator backed by `GET /users/me` and single-flight refresh.
Future<String?> validateSessionViaBackend(ApiClient apiClient) async {
  final response = await apiClient.get(ApiEndpoints.userMe);
  final raw = response.data;
  if (raw is Map) {
    final inner = raw['data'] is Map ? raw['data'] as Map : raw;
    final userMap = inner['user'] is Map ? inner['user'] as Map : inner;
    final id = userMap['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }
  }
  return null;
}

/// Holds the display name of the active user (including Development Guest).
final activeUserDisplayNameProvider = StateProvider<String?>((ref) => null);

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
    final refreshToken = await tokens.getRefreshToken();
    final storedUserId = await secureStorage.read(StorageKeys.userId);

    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;

    if (!hasAccess && !hasRefresh) {
      final established = await _tryEstablishDevGuestSession();
      if (!established) {
        state = const SessionState.unauthenticated();
      }
      return;
    }

    final validator = ref.read(sessionValidatorProvider);
    if (validator != null) {
      try {
        final verifiedUserId = await validator();
        final resolvedId = (verifiedUserId != null && verifiedUserId.isNotEmpty)
            ? verifiedUserId
            : ((storedUserId != null && storedUserId.isNotEmpty)
                  ? storedUserId
                  : null);
        if (resolvedId != null) {
          await secureStorage.write(StorageKeys.userId, resolvedId);
        }
        state = SessionState(
          status: SessionStatus.authenticated,
          userId: resolvedId,
        );
        return;
      } catch (error) {
        final failure = ErrorMapper.map(error);
        if (failure is UnauthorizedFailure || failure is ForbiddenFailure) {
          await logout();
          await _tryEstablishDevGuestSession();
          return;
        }
        // On transient network/timeout failure, retain provisional session only if an access token exists.
        if (!hasAccess) {
          state = const SessionState.unauthenticated();
          return;
        }
      }
    }

    if (hasAccess) {
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

  /// Automatically authenticates the fixed non-admin Development Guest account
  /// with the backend when running in DEVELOPMENT mode. Strictly disabled in Production.
  Future<bool> _tryEstablishDevGuestSession() async {
    final config = ref.read(appConfigProvider);
    if (!config.enableDevGuestAuth || config.environment.isProduction) {
      return false;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final tokens = ref.read(tokenProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);

      final response = await apiClient.post(
        ApiEndpoints.devGuestLogin,
        data: const <String, dynamic>{},
      );
      final raw = response.data;
      if (raw is! Map) return false;

      final payload = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : Map<String, dynamic>.from(raw);
      final tokenMap = payload['tokens'] is Map
          ? Map<String, dynamic>.from(payload['tokens'] as Map)
          : const <String, dynamic>{};
      final userMap = payload['user'] is Map
          ? Map<String, dynamic>.from(payload['user'] as Map)
          : const <String, dynamic>{};

      final accessToken = tokenMap['accessToken']?.toString() ?? '';
      final refreshToken = tokenMap['refreshToken']?.toString() ?? '';
      final userId = userMap['id']?.toString();
      final fullName = userMap['fullName']?.toString();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        return false;
      }

      await tokens.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (userId != null && userId.isNotEmpty) {
        await secureStorage.write(StorageKeys.userId, userId);
      }
      if (fullName != null && fullName.isNotEmpty) {
        ref.read(activeUserDisplayNameProvider.notifier).state = fullName;
      }

      state = SessionState(
        status: SessionStatus.authenticated,
        userId: userId,
      );
      return true;
    } catch (_) {
      // Fail safely: allow browsing Home even if backend dev-guest is unavailable or disabled.
      return false;
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
