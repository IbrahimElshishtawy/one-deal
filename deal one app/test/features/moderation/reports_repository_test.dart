import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/moderation/data/dto/report_dto.dart';
import 'package:market_space/features/moderation/data/repositories/reports_repository_impl.dart';

class MockReportsApiClient implements ApiClient {
  final List<String> requestedPaths = [];
  dynamic lastPayload;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<T>> post<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    requestedPaths.add(path);
    lastPayload = data;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
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
  Future<Response<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }
}

void main() {
  group('ReportsRepositoryImpl', () {
    test('fileReport posts report payload to reports endpoint', () async {
      final mockClient = MockReportsApiClient();
      final repository = ReportsRepositoryImpl(apiClient: mockClient);

      await repository.fileReport(const CreateReportDto(
        listingId: 'listing-fake',
        reason: 'scam',
        notes: 'إعلان وهمي بسعر غير حقيقي',
      ));

      expect(mockClient.requestedPaths, contains(ApiEndpoints.reports));
      expect(mockClient.lastPayload['listingId'], 'listing-fake');
      expect(mockClient.lastPayload['reason'], 'scam');
      expect(mockClient.lastPayload['notes'], 'إعلان وهمي بسعر غير حقيقي');
    });
  });
}
