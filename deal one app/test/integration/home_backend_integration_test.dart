import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/config/app_config.dart';
import 'package:market_space/core/config/environment.dart';
import 'package:market_space/core/logging/app_logger.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

class _AlwaysConnectedNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream<bool>.empty();
}

class _InMemorySecureStorage implements SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;
}

class _InMemoryTokenProvider implements TokenProvider {
  String? _access;
  String? _refresh;

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<bool> hasValidToken() async => _access != null && _access!.isNotEmpty;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }
}

void main() {
  group('AppConfig Fail-Closed Production Safety', () {
    test('production forces enableDevGuestAuth=false even if true is passed', () {
      const cfg = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: AppConfig.defaultProductionApiBaseUrl,
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 15),
        enableLogging: false,
        enableMockMode: false,
        enableDevGuestAuth: true,
      );
      expect(cfg.enableDevGuestAuth, isFalse);
      expect(AppConfig.production().enableDevGuestAuth, isFalse);
    });

    test('development enables Home-first startup and Dev Guest auth', () {
      final cfg = AppConfig.development();
      expect(cfg.startOnHome, isTrue);
      expect(cfg.enableDevGuestAuth, isTrue);
    });
  });

  group('Real End-to-End Integration (Backend DB -> API -> Dio -> Repository -> Riverpod)', () {
    test('authenticates dev guest and fetches real categories, featured, recommended, details, and search', () async {
      final config = AppConfig.development();
      final tokenProv = _InMemoryTokenProvider();
      final secureStorage = _InMemorySecureStorage();
      final networkInfo = _AlwaysConnectedNetworkInfo();
      final apiClient = DioApiClient.create(
        appConfig: config,
        networkInfo: networkInfo,
        tokenProvider: tokenProv,
        logger: AppLoggerImpl(isLoggingEnabled: false),
      );

      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          networkInfoProvider.overrideWithValue(networkInfo),
          secureStorageServiceProvider.overrideWithValue(secureStorage),
          tokenProvider.overrideWithValue(tokenProv),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );
      addTearDown(container.dispose);

      // 1. Auto-establish Development Guest session against real backend
      await container.read(sessionProvider.notifier).restoreSession();
      final session = container.read(sessionProvider);
      expect(session.isAuthenticated, isTrue);
      expect(container.read(activeUserDisplayNameProvider), isNotEmpty);

      // Verify /auth/me works with the issued JWT
      final meRes = await apiClient.get(ApiEndpoints.authMe);
      expect(meRes.statusCode, 200);

      // 2. Fetch real categories from DB
      final categories = await container.read(categoryTreeProvider.future);
      expect(categories.length, greaterThanOrEqualTo(6));

      // 3. Fetch real featured & recommended listings from DB
      final featured = await container.read(featuredListingsProvider.future);
      expect(featured, isNotEmpty);
      expect(featured.first.isFeatured, isTrue);
      expect(featured.first.cityNameAr, isNotEmpty);

      final recommended = await container.read(recommendedListingsProvider.future);
      expect(recommended, isNotEmpty);

      // 4. Fetch real product details from DB
      final detail = await container.read(
        listingDetailsFamily(featured.first.id).future,
      );
      expect(detail.id, featured.first.id);
      expect(detail.title, isNotEmpty);
      expect(detail.sellerName, isNotEmpty);

      // 5. Execute real backend search with category + sorting
      container.read(searchActiveQueryDtoProvider.notifier).state =
          const SearchQueryDto(
        query: 'شقة',
        categorySlug: 'real-estate',
        rooms: 3,
        sort: 'price_asc',
      );
      final searchResult = await container.read(searchResultsProvider.future);
      expect(searchResult.items, isNotEmpty);
    });
  });
}
