import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/repositories/listings_repository_impl.dart';

class MockListingsApiClient implements ApiClient {
  final Map<String, dynamic> responses;
  final List<String> requestedPaths = [];

  MockListingsApiClient(this.responses);

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
  group('ListingsRepositoryImpl', () {
    test('getListingsFeed parses items and verifies sellerPhone is null in public feed', () async {
      final mockFeedData = {
        'data': [
          {
            'id': 'listing-123',
            'title': 'هيونداي إلنترا 2021',
            'description': 'سيارة بحالة ممتازة فابريكا',
            'price': 750000,
            'currency': 'EGP',
            'condition': 'USED',
            'listingKind': 'sale',
            'category': {
              'id': 'cat-cars',
              'nameAr': 'سيارات للبيع',
              'nameEn': 'Cars for Sale',
              'slug': 'cars-for-sale',
            },
            'area': {
              'nameAr': 'مدينة نصر',
              'city': {
                'nameAr': 'القاهرة',
                'governorate': {'nameAr': 'محافظة القاهرة'}
              }
            },
            'media': [
              {
                'id': 'med-1',
                'mediaType': 'image',
                'publicUrl': 'https://cdn.example.com/img1.jpg',
                'sortOrder': 0,
              }
            ],
            'sellerName': 'أحمد محمود',
            'sellerPhone': null, // PRIVACY INVARIANT: Must be null
            'sellerType': 'individual',
            'isVerified': true,
            'attributes': {'year': 2021, 'make': 'Hyundai'},
            'viewsCount': 42,
            'createdAt': '2026-11-01T12:00:00.000Z',
          }
        ],
        'meta': {
          'nextCursor': '2026-11-01T12:00:00.000Z',
          'limit': 20,
          'hasMore': true,
        }
      };

      final mockClient = MockListingsApiClient({
        ApiEndpoints.listings: mockFeedData,
      });

      final repository = ListingsRepositoryImpl(apiClient: mockClient);
      final feed = await repository.getListingsFeed(const FilterListingsDto());

      expect(feed.items.length, 1);
      final item = feed.items.first;
      expect(item.id, 'listing-123');
      expect(item.title, 'هيونداي إلنترا 2021');
      expect(item.price, 750000.0);
      expect(item.sellerPhone, isNull); // Privacy verified
      expect(item.primaryImageUrl, 'https://cdn.example.com/img1.jpg');
      expect(item.localizedLocation('ar'), 'القاهرة - مدينة نصر');
      expect(feed.hasMore, isTrue);
      expect(feed.nextCursor, '2026-11-01T12:00:00.000Z');
    });

    test('revealContact calls reveal endpoint and returns seller phone & Cairo quota', () async {
      final mockRevealData = {
        'phone': '+201012345678',
        'sellerName': 'أحمد محمود',
        'whatsapp': 'https://wa.me/201012345678',
        'whatsappUrl': 'https://wa.me/201012345678',
        'remainingDailyQuota': 4,
        'dailyLimit': 5,
      };

      final mockClient = MockListingsApiClient({
        ApiEndpoints.revealContact('listing-123'): mockRevealData,
      });

      final repository = ListingsRepositoryImpl(apiClient: mockClient);
      final reveal = await repository.revealContact('listing-123');

      expect(reveal.phone, '+201012345678');
      expect(reveal.sellerName, 'أحمد محمود');
      expect(reveal.whatsappUrl, 'https://wa.me/201012345678');
      expect(reveal.remainingDailyQuota, 4);
      expect(reveal.dailyLimit, 5);
      expect(mockClient.requestedPaths, contains(ApiEndpoints.revealContact('listing-123')));
    });

    test('deleteListing executes deletion via API client', () async {
      final mockClient = MockListingsApiClient({});
      final repository = ListingsRepositoryImpl(apiClient: mockClient);

      await repository.deleteListing('listing-123');
      expect(mockClient.requestedPaths, contains(ApiEndpoints.listingDetails('listing-123')));
    });
  });
}
