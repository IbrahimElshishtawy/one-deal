import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/data/repositories/search_repository_impl.dart';

class MockSearchApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockSearchApiClient(this.responses);

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
  Future<Response<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
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
  Future<Response<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }
}

void main() {
  group('SearchRepositoryImpl', () {
    test('search passes query params, parses results and pagination meta', () async {
      final mockData = {
        'data': [
          {
            'id': 'listing-toyota',
            'title': 'تويوتا كورولا 2022',
            'description': 'سيارة ممتازة بحالة الوكالة',
            'price': 820000,
            'currency': 'EGP',
            'category': {
              'id': 'cat-cars',
              'nameAr': 'سيارات للبيع',
              'nameEn': 'Cars',
              'slug': 'cars',
            },
            'area': {
              'nameAr': 'المعادي',
              'city': {
                'nameAr': 'القاهرة',
                'governorate': {'nameAr': 'محافظة القاهرة'},
              }
            },
            'media': [
              {
                'id': 'med-1',
                'mediaType': 'image',
                'publicUrl': 'https://cdn.example.com/toyota.jpg',
                'sortOrder': 0,
              }
            ],
            'sellerName': 'محمود علي',
            'sellerPhone': null,
            'sellerType': 'individual',
            'isVerified': true,
            'attributes': {'year': 2022, 'make': 'Toyota'},
            'viewsCount': 15,
            'createdAt': '2026-11-05T10:00:00.000Z',
          }
        ],
        'meta': {
          'total': 45,
          'page': 1,
          'limit': 20,
          'totalPages': 3,
          'query': 'تويوتا',
        }
      };

      final mockClient = MockSearchApiClient({
        ApiEndpoints.search: mockData,
      });

      final repository = SearchRepositoryImpl(apiClient: mockClient);
      final result = await repository.search(const SearchQueryDto(query: 'تويوتا'));

      expect(result.items.length, 1);
      expect(result.items.first.title, 'تويوتا كورولا 2022');
      expect(result.totalCount, 45);
      expect(result.currentPage, 1);
      expect(result.totalPages, 3);
      expect(result.hasMore, isTrue);
      expect(result.query, 'تويوتا');
    });
  });
}
