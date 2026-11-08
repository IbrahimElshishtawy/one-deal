import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/locations/data/repositories/locations_repository_impl.dart';

class MockLocationsApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockLocationsApiClient(this.responses);

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
  group('LocationsRepositoryImpl', () {
    test('getGovernorates parses governorates with embedded cities', () async {
      final mockData = [
        {
          'id': 1,
          'nameAr': 'القاهرة',
          'nameEn': 'Cairo',
          'slug': 'cairo',
          'sortOrder': 1,
          'isActive': true,
          'cities': [
            {
              'id': 101,
              'governorateId': 1,
              'nameAr': 'مدينة نصر',
              'nameEn': 'Nasr City',
              'slug': 'nasr-city',
              'isActive': true,
            },
            {
              'id': 102,
              'governorateId': 1,
              'nameAr': 'المعادي',
              'nameEn': 'Maadi',
              'slug': 'maadi',
              'isActive': true,
            }
          ]
        },
        {
          'id': 2,
          'nameAr': 'الجيزة',
          'nameEn': 'Giza',
          'slug': 'giza',
          'sortOrder': 2,
          'isActive': true,
          'cities': [
            {
              'id': 201,
              'governorateId': 2,
              'nameAr': 'الدقي',
              'nameEn': 'Dokki',
              'slug': 'dokki',
              'isActive': true,
            }
          ]
        }
      ];

      final mockClient = MockLocationsApiClient({
        ApiEndpoints.governorates: mockData,
      });

      final repository = LocationsRepositoryImpl(apiClient: mockClient);
      final result = await repository.getGovernorates();

      expect(result.length, 2);
      expect(result[0].nameAr, 'القاهرة');
      expect(result[0].localizedName('ar'), 'القاهرة');
      expect(result[0].localizedName('en'), 'Cairo');
      expect(result[0].cities.length, 2);
      expect(result[0].cities[0].nameAr, 'مدينة نصر');

      // Verify caching: second call does not query API
      final cachedResult = await repository.getGovernorates();
      expect(cachedResult.length, 2);
      expect(mockClient.requestedPaths.where((p) => p == ApiEndpoints.governorates).length, 1);
    });

    test('getAreasForCity parses areas correctly', () async {
      final mockAreas = [
        {
          'id': 'area-1',
          'cityId': 101,
          'nameAr': 'الحي السابع',
          'nameEn': '7th District',
          'isActive': true,
        },
        {
          'id': 'area-2',
          'cityId': 101,
          'nameAr': 'مكرم عبيد',
          'nameEn': 'Makram Ebeid',
          'isActive': true,
        }
      ];

      final mockClient = MockLocationsApiClient({
        ApiEndpoints.cityAreas(101): mockAreas,
      });

      final repository = LocationsRepositoryImpl(apiClient: mockClient);
      final areas = await repository.getAreasForCity(101);

      expect(areas.length, 2);
      expect(areas[0].nameAr, 'الحي السابع');
      expect(areas[1].localizedName('en'), 'Makram Ebeid');
    });
  });
}
