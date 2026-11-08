import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';

class FakeApiClient implements ApiClient {
  String? lastGetPath;
  dynamic nextGetResponseData;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    return Response<T>(
      data: nextGetResponseData as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> put<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> patch<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      throw UnimplementedError();

  @override
  Future<Response<T>> delete<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) =>
      throw UnimplementedError();
}

void main() {
  group('CategoriesRepositoryImpl', () {
    late FakeApiClient apiClient;
    late CategoriesRepositoryImpl repository;

    setUp(() {
      apiClient = FakeApiClient();
      repository = CategoriesRepositoryImpl(apiClient: apiClient);
    });

    test('getCategoryTree parses nested taxonomy and caches in-memory', () async {
      apiClient.nextGetResponseData = {
        'success': true,
        'data': [
          {
            'id': 'cat_1',
            'slug': 'real-estate',
            'nameAr': 'عقارات',
            'nameEn': 'Real Estate',
            'children': [
              {
                'id': 'cat_1_1',
                'slug': 'apartments-sale',
                'nameAr': 'شقق للبيع',
                'nameEn': 'Apartments for Sale',
                'parentId': 'cat_1',
              }
            ],
          }
        ],
      };

      final tree = await repository.getCategoryTree();

      expect(tree.length, equals(1));
      expect(tree.first.nameAr, equals('عقارات'));
      expect(tree.first.subcategories.length, equals(1));
      expect(tree.first.subcategories.first.nameAr, equals('شقق للبيع'));

      // Test memory cache: subsequent call shouldn't call network if cached
      apiClient.nextGetResponseData = null;
      final cachedTree = await repository.getCategoryTree();
      expect(cachedTree.length, equals(1));
    });

    test('getCategoryFields parses dynamic attribute fields schema', () async {
      apiClient.nextGetResponseData = {
        'success': true,
        'data': [
          {
            'fieldKey': 'rooms',
            'fieldType': 'number',
            'labelAr': 'عدد الغرف',
            'labelEn': 'Number of Rooms',
            'isRequired': true,
          },
          {
            'fieldKey': 'finishing',
            'fieldType': 'select',
            'labelAr': 'نوع التشطيب',
            'labelEn': 'Finishing Type',
            'validationRules': {
              'options': ['سوبر لوكس', 'نصف تشطيب', 'بدون تشطيب'],
            },
          }
        ],
      };

      final fields = await repository.getCategoryFields('apartments-sale');

      expect(fields.length, equals(2));
      expect(fields[0].fieldKey, equals('rooms'));
      expect(fields[0].fieldType, equals(CategoryFieldType.number));
      expect(fields[0].isRequired, isTrue);

      expect(fields[1].fieldKey, equals('finishing'));
      expect(fields[1].fieldType, equals(CategoryFieldType.select));
      expect(fields[1].options.length, equals(3));
    });
  });
}
