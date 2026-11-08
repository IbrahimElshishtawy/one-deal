import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/media/data/repositories/media_repository_impl.dart';

class MockMediaApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockMediaApiClient(this.responses);

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
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
  Future<Response<T>> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) {
    throw UnimplementedError();
  }
}

void main() {
  group('MediaRepositoryImpl', () {
    test('requestUploadUrls requests presigned targets and parses keys and uploadUrls', () async {
      final mockPresigned = [
        {
          'key': 'uploads/images/2026-11/user-123/img-abc.jpg',
          'uploadUrl': 'https://deal-one.r2.cloudflarestorage.com/uploads/images/2026-11/user-123/img-abc.jpg?token=xyz',
          'publicUrl': 'https://cdn.deal-one.com/uploads/images/2026-11/user-123/img-abc.jpg',
          'contentType': 'image/jpeg',
        }
      ];

      final mockClient = MockMediaApiClient({
        ApiEndpoints.imageUploadUrls: mockPresigned,
      });

      final repository = MediaRepositoryImpl(apiClient: mockClient);
      final targets = await repository.requestUploadUrls(['image/jpeg']);

      expect(targets.length, 1);
      expect(targets.first.storageKey, 'uploads/images/2026-11/user-123/img-abc.jpg');
      expect(targets.first.uploadUrl, contains('r2.cloudflarestorage.com'));
      expect(targets.first.publicUrl, contains('cdn.deal-one.com'));
      expect(mockClient.requestedPaths, contains(ApiEndpoints.imageUploadUrls));
    });
  });
}
