import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/favorites/data/repositories/favorites_repository_impl.dart';

class MockFavoritesApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockFavoritesApiClient(this.responses);

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    requestedPaths.add(path);
    if (responses.containsKey(path)) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: responses[path] as T,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(requestOptions: RequestOptions(path: path), statusCode: 404),
    );
  }

  @override
  Future<Response<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    requestedPaths.add(path);
    if (responses.containsKey(path)) {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        data: responses[path] as T,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(requestOptions: RequestOptions(path: path), statusCode: 404),
    );
  }

  @override
  Future<Response<T>> put<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> patch<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    requestedPaths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }
}

void main() {
  group('FavoritesRepositoryImpl', () {
    test('getMyFavorites parses saved items correctly', () async {
      final mockData = [
        {
          'favoriteId': 'fav-1',
          'savedAt': '2026-11-06T10:00:00.000Z',
          'listing': {
            'id': 'listing-456',
            'title': 'شقة للإيجار في المعادي',
            'description': 'تشطيب سوبر لوكس',
            'price': 15000,
            'currency': 'EGP',
            'category': {
              'id': 'cat-re',
              'nameAr': 'عقارات',
              'nameEn': 'Real Estate',
              'slug': 'real-estate',
            },
            'area': {
              'nameAr': 'دجلة',
              'city': {
                'nameAr': 'المعادي',
                'governorate': {'nameAr': 'محافظة القاهرة'},
              }
            },
            'media': [
              {
                'id': 'med-1',
                'mediaType': 'image',
                'publicUrl': 'https://cdn.example.com/apt.jpg',
                'sortOrder': 0,
              }
            ],
            'sellerName': 'مكتب العقارية',
            'sellerPhone': null,
            'sellerType': 'broker',
            'isVerified': true,
            'attributes': {'rooms': 3, 'baths': 2},
            'viewsCount': 89,
            'createdAt': '2026-11-04T12:00:00.000Z',
          }
        }
      ];

      final mockClient = MockFavoritesApiClient({
        ApiEndpoints.favorites: mockData,
      });

      final repository = FavoritesRepositoryImpl(apiClient: mockClient);
      final list = await repository.getMyFavorites();

      expect(list.length, 1);
      expect(list.first.favoriteId, 'fav-1');
      expect(list.first.listing.id, 'listing-456');
      expect(list.first.listing.title, 'شقة للإيجار في المعادي');
      expect(list.first.listing.sellerPhone, isNull);
    });

    test('toggleFavorite sends request to favorite endpoint and parses boolean state', () async {
      final mockClient = MockFavoritesApiClient({
        ApiEndpoints.favoriteItem('listing-456'): {
          'success': true,
          'isFavorite': true,
          'favoriteId': 'fav-new',
        }
      });

      final repository = FavoritesRepositoryImpl(apiClient: mockClient);
      final result = await repository.toggleFavorite('listing-456');

      expect(result.success, isTrue);
      expect(result.isFavorite, isTrue);
      expect(mockClient.requestedPaths, contains(ApiEndpoints.favoriteItem('listing-456')));
    });

    test('removeFavorite calls DELETE on favorite item endpoint', () async {
      final mockClient = MockFavoritesApiClient({});
      final repository = FavoritesRepositoryImpl(apiClient: mockClient);

      await repository.removeFavorite('listing-456');
      expect(mockClient.requestedPaths, contains(ApiEndpoints.favoriteItem('listing-456')));
    });
  });
}
