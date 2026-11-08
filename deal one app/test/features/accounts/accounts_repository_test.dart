import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/accounts/data/repositories/accounts_repository_impl.dart';

class MockAccountsApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockAccountsApiClient(this.responses);

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
  group('AccountsRepositoryImpl', () {
    test('getMyAccounts parses user account memberships with roles', () async {
      final mockData = [
        {
          'id': 'acc-1',
          'accountType': 'business',
          'displayName': 'معرض النصر للسيارات',
          'slug': 'el-nasr-motors',
          'bio': 'أفضل السيارات المستعملة والجديدة',
          'logoUrl': 'https://cdn.example.com/logo.png',
          'verificationStatus': 'approved',
          'isActive': true,
          'role': 'owner',
          'joinedAt': '2026-10-01T10:00:00.000Z',
        }
      ];

      final mockClient = MockAccountsApiClient({
        ApiEndpoints.myAccounts: mockData,
      });

      final repository = AccountsRepositoryImpl(apiClient: mockClient);
      final accounts = await repository.getMyAccounts();

      expect(accounts.length, 1);
      final acc = accounts.first;
      expect(acc.displayName, 'معرض النصر للسيارات');
      expect(acc.role, 'owner');
      expect(acc.isOwner, isTrue);
      expect(acc.isVerified, isTrue);
      expect(mockClient.requestedPaths, contains(ApiEndpoints.myAccounts));
    });

    test('getAccountBranches parses branch list', () async {
      final mockData = [
        {
          'id': 'branch-1',
          'accountId': 'acc-1',
          'name': 'فرع التجمع الخامس',
          'address': 'شارع التسعين الشمالي',
          'cityId': 101,
          'latitude': 30.0123,
          'longitude': 31.4321,
          'phone': '+201000000000',
          'isMain': true,
        }
      ];

      final mockClient = MockAccountsApiClient({
        ApiEndpoints.accountBranches('acc-1'): mockData,
      });

      final repository = AccountsRepositoryImpl(apiClient: mockClient);
      final branches = await repository.getAccountBranches('acc-1');

      expect(branches.length, 1);
      expect(branches.first.name, 'فرع التجمع الخامس');
      expect(branches.first.isMain, isTrue);
      expect(mockClient.requestedPaths, contains(ApiEndpoints.accountBranches('acc-1')));
    });
  });
}
