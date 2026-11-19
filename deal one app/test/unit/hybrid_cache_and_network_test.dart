import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/core/cache/price_freshness_service.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/errors/error_presenter.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/storage/preferences_service.dart';

class _InMemoryPreferencesService implements PreferencesService {
  final Map<String, Object> _store = {};

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<bool?> getBool(String key) async => _store[key] as bool?;

  @override
  Future<int?> getInt(String key) async => _store[key] as int?;

  @override
  Future<double?> getDouble(String key) async => _store[key] as double?;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<void> setDouble(String key, double value) async => _store[key] = value;

  @override
  Future<void> setString(String key, String value) async => _store[key] = value;
}

class _FakeNetworkInfo implements NetworkInfo {
  final bool connected;
  _FakeNetworkInfo({this.connected = true});

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class _FakeBatchPriceApiClient implements ApiClient {
  int postCount = 0;
  List<String> lastRequestedIds = [];

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    postCount++;
    final ids = List<String>.from((data as Map)['ids'] as List);
    lastRequestedIds = ids;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'success': true,
        'data': {
          'generatedAt': DateTime.now().toIso8601String(),
          'priceFreshnessTtlSeconds': 60,
          'items': ids
              .map(
                (id) => {
                  'id': id,
                  'price': 99999,
                  'currency': 'EGP',
                  'availabilityStatus': 'available',
                  'updatedAt': DateTime.now().toIso8601String(),
                },
              )
              .toList(),
        },
      } as T,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('HybridCacheManager', () {
    test('stores and reads versioned L1/L2 cache with TTL and corrupt-JSON safety', () async {
      final prefs = _InMemoryPreferencesService();
      final cache = HybridCacheManager(preferencesService: prefs);

      await cache.write(
        'section:real-estate',
        {'title': 'Real Estate', 'count': 60},
        ttl: const Duration(minutes: 3),
      );

      final record = await cache.read('section:real-estate');
      expect(record, isNotNull);
      expect(record!.isFresh, isTrue);
      expect(record.payload['count'], 60);

      // Corrupt JSON in L2 should never crash
      await prefs.setString('d1_cache_v2:corrupt', '{not-valid-json');
      final corruptRecord = await cache.read('corrupt');
      expect(corruptRecord, isNull);
    });

    test('persists deduplicated MRU search history and last viewed listings', () async {
      final prefs = _InMemoryPreferencesService();
      final cache = HybridCacheManager(preferencesService: prefs);

      await cache.addSearchHistory('شقة التجمع');
      await cache.addSearchHistory('تويوتا كورولا');
      await cache.addSearchHistory('شقة التجمع');

      final history = await cache.getSearchHistory();
      expect(history, ['شقة التجمع', 'تويوتا كورولا']);

      await cache.recordViewedListing(
        id: 'l-1',
        title: 'شقة 180م',
        price: 3200000,
        currency: 'EGP',
      );
      final viewed = await cache.getLastViewedListings();
      expect(viewed.length, 1);
      expect(viewed.first['id'], 'l-1');
    });
  });

  group('LivePricesNotifier (Batch Price Refresh)', () {
    test('batches multiple listing IDs into a single POST request and caches freshness', () async {
      final fakeApi = _FakeBatchPriceApiClient();
      final notifier = LivePricesNotifier(fakeApi);

      await notifier.refreshBatch(['id-1', 'id-2', 'id-3']);
      expect(fakeApi.postCount, 1);
      expect(fakeApi.lastRequestedIds, ['id-1', 'id-2', 'id-3']);
      expect(notifier.resolvePrice('id-1', 100), 99999);
      expect(notifier.isPriceFresh('id-2'), isTrue);

      // Subsequent call within TTL should NOT trigger another network call
      await notifier.refreshBatch(['id-1', 'id-2', 'id-3']);
      expect(fakeApi.postCount, 1);
    });
  });

  group('DioApiClient Request Deduplication', () {
    test('coalesces identical concurrent GET requests into one HTTP call', () async {
      int adapterHits = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            adapterHits++;
            await Future<void>.delayed(const Duration(milliseconds: 40));
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'ok': true},
              ),
            );
          },
        ),
      );

      final client = DioApiClient(
        dio: dio,
        networkInfo: _FakeNetworkInfo(connected: true),
      );

      final results = await Future.wait([
        client.get('/home', queryParameters: {'limit': 10}),
        client.get('/home', queryParameters: {'limit': 10}),
        client.get('/home', queryParameters: {'limit': 10}),
      ]);

      expect(adapterHits, 1);
      expect(results.length, 3);
    });
  });

  group('ErrorPresenter', () {
    test('maps every HTTP/network failure to clean Arabic copy with no stack traces', () {
      final offline = ErrorPresenter.present(const NetworkFailure(), isArabic: true);
      expect(offline.kind, FeatureErrorKind.offline);
      expect(offline.title, contains('إنترنت'));

      final rateLimit = ErrorPresenter.present(
        const RateLimitFailure(),
        isArabic: true,
      );
      expect(rateLimit.kind, FeatureErrorKind.rateLimited);

      final server = ErrorPresenter.present(
        const ServerFailure(userFriendlyMessage: 'Server down'),
        isArabic: true,
      );
      expect(server.kind, FeatureErrorKind.server);
      expect(server.message.contains('Exception'), isFalse);
    });
  });
}
