import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/quotas/data/repositories/quotas_repository_impl.dart';

class MockQuotasApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockQuotasApiClient(this.responses);

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
  group('QuotasRepositoryImpl', () {
    test('getMyQuotaUsage parses Africa/Cairo quota usage correctly', () async {
      final mockData = {
        'timezone': 'Africa/Cairo',
        'date': '2026-11-08',
        'contactReveals': {
          'used': 2,
          'limit': 5,
          'remaining': 3,
          'isLimitReached': false,
        }
      };

      final mockClient = MockQuotasApiClient({
        ApiEndpoints.myQuotas: mockData,
      });

      final repository = QuotasRepositoryImpl(apiClient: mockClient);
      final usage = await repository.getMyQuotaUsage();

      expect(usage.timezone, 'Africa/Cairo');
      expect(usage.date, '2026-11-08');
      expect(usage.used, 2);
      expect(usage.limit, 5);
      expect(usage.remaining, 3);
      expect(usage.isLimitReached, isFalse);
      expect(mockClient.requestedPaths, contains(ApiEndpoints.myQuotas));
    });
  });
}
