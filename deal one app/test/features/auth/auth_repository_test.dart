import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/features/auth/data/repositories/auth_repository_impl.dart';

class MockTokenProvider implements TokenProvider {
  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<bool> hasValidToken() async =>
      accessToken != null && accessToken!.isNotEmpty;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class FakeApiClient implements ApiClient {
  String? lastPostPath;
  dynamic lastPostData;
  dynamic nextPostResponseData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return Response<T>(
      data: nextPostResponseData as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();
}

void main() {
  group('AuthRepositoryImpl', () {
    late FakeApiClient apiClient;
    late MockTokenProvider tokenProvider;
    late AuthRepositoryImpl repository;

    setUp(() {
      apiClient = FakeApiClient();
      tokenProvider = MockTokenProvider();
      repository = AuthRepositoryImpl(
        apiClient: apiClient,
        tokenProvider: tokenProvider,
      );
    });

    test('sendOtp sends phone to /auth/otp/send', () async {
      await repository.sendOtp('+201012345678');
      expect(apiClient.lastPostPath, equals('/auth/otp/send'));
      expect(apiClient.lastPostData, equals({'phone': '+201012345678'}));
    });

    test(
      'verifyOtp parses session, saves tokens, and returns AuthSession',
      () async {
        apiClient.nextPostResponseData = {
          'success': true,
          'data': {
            'accessToken': 'jwt_access_123',
            'refreshToken': 'jwt_refresh_456',
            'user': {
              'id': 'user_uuid_1',
              'phone': '+201012345678',
              'fullName': 'أحمد محمد',
              'isPhoneVerified': true,
            },
          },
        };

        final session = await repository.verifyOtp('+201012345678', '123456');

        expect(session.accessToken, equals('jwt_access_123'));
        expect(session.refreshToken, equals('jwt_refresh_456'));
        expect(session.user.fullName, equals('أحمد محمد'));
        expect(tokenProvider.accessToken, equals('jwt_access_123'));
        expect(tokenProvider.refreshToken, equals('jwt_refresh_456'));
      },
    );

    test('logout clears tokens', () async {
      tokenProvider.accessToken = 'token';
      tokenProvider.refreshToken = 'refresh';

      await repository.logout();

      expect(tokenProvider.accessToken, isNull);
      expect(tokenProvider.refreshToken, isNull);
    });
  });
}
