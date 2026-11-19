import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/core/marketplace/section_home_repository.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/network_info.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart';
import 'package:market_space/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart';
import 'package:market_space/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart';
import 'package:market_space/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart';
import 'package:market_space/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/main_hub/presentation/pages/main_hub_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/services_engineering/presentation/pages/services_engineering_home_page.dart';

class _TestPrefs implements PreferencesService {
  final Map<String, Object> _m = {};
  @override
  Future<void> clear() async => _m.clear();
  @override
  Future<bool?> getBool(String key) async => _m[key] as bool?;
  @override
  Future<int?> getInt(String key) async => _m[key] as int?;
  @override
  Future<double?> getDouble(String key) async => _m[key] as double?;
  @override
  Future<String?> getString(String key) async => _m[key] as String?;
  @override
  Future<void> remove(String key) async => _m.remove(key);
  @override
  Future<void> setBool(String key, bool value) async => _m[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _m[key] = value;
  @override
  Future<void> setDouble(String key, double value) async => _m[key] = value;
  @override
  Future<void> setString(String key, String value) async => _m[key] = value;
}

class _TestNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}

class _TestMultiHomeApiClient implements ApiClient {
  Map<String, dynamic> _sampleListing(String id, String title, String slug, double price, Map<String, dynamic> attrs) => {
        'id': id,
        'title': title,
        'description': 'وصف تفصيلي للمنتج من الخادم',
        'price': price,
        'currency': 'EGP',
        'condition': 'NEW',
        'listingKind': slug.contains('rent') ? 'rent' : 'sale',
        'categoryId': 'cat-$slug',
        'category': {'id': 'cat-$slug', 'slug': slug, 'nameAr': 'قسم $slug', 'nameEn': slug},
        'governorateName': 'الغربية',
        'cityName': 'طنطا',
        'areaName': 'شارع النادي',
        'media': const [],
        'attributes': attrs,
        'viewsCount': 120,
        'favoritesCount': 8,
        'sellerName': 'شركة ديل ون المعتمدة',
        'sellerType': 'company',
        'isVerified': true,
        'isFeatured': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    if (path == '/favorites') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {'success': true, 'data': []} as T,
      );
    }

    if (path == '/home') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'schemaVersion': '1.0',
            'priceFreshnessTtlSeconds': 60,
            'categories': [
              {'id': '1', 'slug': 'real-estate', 'nameAr': 'عقارات وأراضٍ', 'nameEn': 'Real Estate', 'listingsCount': 60},
              {'id': '2', 'slug': 'home-appliances', 'nameAr': 'أجهزة وديكور', 'nameEn': 'Appliances', 'listingsCount': 60},
              {'id': '3', 'slug': 'services', 'nameAr': 'خدمات وهندسة', 'nameEn': 'Services', 'listingsCount': 60},
              {'id': '4', 'slug': 'building-materials', 'nameAr': 'مواد بناء وكهرباء', 'nameEn': 'Materials', 'listingsCount': 60},
              {'id': '5', 'slug': 'cars', 'nameAr': 'سيارات وصيانة', 'nameEn': 'Cars', 'listingsCount': 50},
              {'id': '6', 'slug': 'fashion', 'nameAr': 'أزياء وإكسسوارات', 'nameEn': 'Fashion', 'listingsCount': 50},
            ],
            'promotions': [
              {
                'id': 'p1',
                'badgeAr': 'خامات التأسيس',
                'badgeEn': 'Essentials',
                'titleAr': 'ابنِ بيتك على أساس متين',
                'titleEn': 'Build Solid',
                'subtitleAr': 'حديد وإسمنت وطوب',
                'subtitleEn': 'Steel & Cement',
                'ctaAr': 'تصفح المواد',
                'ctaEn': 'Browse',
                'categorySlug': 'building-materials',
                'imageUrl': '',
              },
            ],
            'featured': [_sampleListing('l1', 'شقة مودرن 175م', 'apartments-for-sale', 3200000, {'rooms': 3, 'baths': 2, 'area_sqm': 175})],
            'latest': [_sampleListing('l2', 'صيانة تكييفات فورية', 'ac-maintenance', 250, {})],
            'recommended': [_sampleListing('l3', 'توريد أسمنت وحديد', 'steel-rebar', 38500, {'unit_of_measure': 'طن'})],
          },
        } as T,
      );
    }

    if (path.startsWith('/home/sections/')) {
      final slug = path.replaceFirst('/home/sections/', '');
      final item = _sampleListing('sec-$slug-1', 'إعلان قسم $slug', slug, 150000, {
        'rooms': 3,
        'baths': 2,
        'area_sqm': 180,
        'year': 2026,
        'transmission': 'أوتوماتيك',
        'brand': 'ZARA',
        'unit_of_measure': 'طن',
      });
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'schemaVersion': '1.0',
            'priceFreshnessTtlSeconds': 60,
            'section': {
              'id': 'root-$slug',
              'slug': slug,
              'canonicalSlug': slug,
              'nameAr': 'قسم $slug',
              'nameEn': slug,
              'listingsCount': 50,
              'subcategories': [
                {'id': 'sub-1', 'slug': '$slug-sub1', 'nameAr': 'تصنيف فرعي 1', 'nameEn': 'Sub 1', 'listingsCount': 25},
                {'id': 'sub-2', 'slug': '$slug-sub2', 'nameAr': 'تصنيف فرعي 2', 'nameEn': 'Sub 2', 'listingsCount': 25},
              ],
            },
            'promotions': [
              {
                'id': 'sp1',
                'badgeAr': 'عرض القسم',
                'badgeEn': 'Deal',
                'titleAr': 'عروض خاصة لقسم $slug',
                'titleEn': 'Special Offers',
                'subtitleAr': 'أفضل الأسعار من الموردين المعتمدين',
                'subtitleEn': 'Best prices',
                'ctaAr': 'تصفح الآن',
                'ctaEn': 'Browse',
                'categorySlug': slug,
                'imageUrl': '',
              },
            ],
            'livePreviews': [
              {
                'listingId': 'sec-$slug-1',
                'title': 'معاينة حية $slug',
                'price': 2500000,
                'currency': 'EGP',
                'imageUrl': '',
                'mediaCount': 5,
                'sellerName': 'أحمد العقارية',
                'isVerified': true,
              },
            ],
            'featured': [item],
            'latest': [item],
            'recommended': [item],
            'providers': [
              {
                'id': 'prov-1',
                'displayName': 'شركة الصفا المعتمدة',
                'slug': 'safa',
                'accountType': 'company',
                'isVerified': true,
                'specialtyAr': 'وكالة معتمدة - صيانة ومبيعات',
                'specialtyEn': 'Certified Partner',
                'listingsCount': 12,
              },
            ],
            'filterConfig': {
              'sectionSlug': slug,
              'supportsPriceRange': true,
              'supportsLocation': true,
              'supportsCondition': true,
              'supportsListingKind': slug == 'real-estate' || slug == 'cars',
              'listingKindOptions': [
                {'value': 'sale', 'labelAr': 'للبيع', 'labelEn': 'Sale'},
                {'value': 'rent', 'labelAr': 'للإيجار', 'labelEn': 'Rent'},
              ],
              'sortOptions': [
                {'value': 'newest', 'labelAr': 'الأحدث', 'labelEn': 'Newest'},
              ],
              'fields': [
                {'key': 'rooms', 'labelAr': 'عدد الغرف', 'labelEn': 'Rooms', 'type': 'number', 'options': [], 'sortOrder': 1},
              ],
            },
          },
        } as T,
      );
    }

    // Default /listings response
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'success': true,
        'data': [_sampleListing('list-1', 'إعلان حديث', 'real-estate', 900000, {})],
        'meta': {'hasMore': false, 'nextCursor': null},
      } as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': true, 'data': {'items': []}} as T,
    );
  }

  @override
  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();
  @override
  Future<Response<T>> patch<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();
  @override
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) => throw UnimplementedError();
}

Widget _wrapWithProviders(Widget child) {
  final prefs = _TestPrefs();
  final api = _TestMultiHomeApiClient();
  final cache = HybridCacheManager(preferencesService: prefs);
  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      networkInfoProvider.overrideWithValue(_TestNetworkInfo()),
      apiClientProvider.overrideWithValue(api),
      hybridCacheManagerProvider.overrideWithValue(cache),
      sectionHomeRepositoryProvider.overrideWithValue(
        SectionHomeRepository(apiClient: api, cache: cache),
      ),
      favoritesRepositoryProvider.overrideWithValue(
        FavoritesRepositoryImpl(apiClient: api),
      ),
    ],
    child: MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('Home 1 — Main Hub renders 6 backend categories, hero promo, and popular section', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const MainHubPage()));
    await tester.pumpAndSettle();

    expect(find.text('الأقسام الرئيسية'), findsOneWidget);
    expect(find.text('عقارات وأراضٍ'), findsOneWidget);
    expect(find.text('أجهزة وديكور'), findsOneWidget);
    expect(find.text('خدمات وهندسة'), findsOneWidget);
    expect(find.text('مواد بناء وكهرباء'), findsOneWidget);
    expect(find.text('سيارات وصيانة'), findsOneWidget);
    expect(find.text('أزياء وإكسسوارات'), findsOneWidget);
    expect(find.text('الخدمات الأكثر طلباً'), findsOneWidget);
  });

  testWidgets('Home 2 — Real Estate renders chips, live previews, and property card specs', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const RealEstateHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('معاينات حية'), findsOneWidget);
    expect(find.text('التفاصيل'), findsOneWidget);
    expect(find.text('3 غرف'), findsOneWidget);
  });

  testWidgets('Home 3 — Appliances & Decor renders segmented toggle, installment card, and products', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const AppliancesDecorHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('الأجهزة الكهربائية'), findsOneWidget);
    expect(find.text('الديكور والأثاث'), findsOneWidget);
    expect(find.text('تقسيط بدون فوائد'), findsOneWidget);
  });

  testWidgets('Home 4 — Services & Engineering renders categories and certified partners', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ServicesEngineeringHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('الأقسام والخدمات'), findsOneWidget);
    expect(find.text('الخدمات الأكثر طلباً'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('شركة الصفا المعتمدة'), 300);
    expect(find.text('شركة الصفا المعتمدة'), findsOneWidget);
  });

  testWidgets('Home 5 — Construction & Electrical renders segmented toggle and material cards', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const ConstructionElectricalHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('مواد البناء'), findsOneWidget);
    expect(find.text('الكهرباء والتأسيس'), findsOneWidget);
    expect(find.text('الخامات الأكثر طلباً'), findsOneWidget);
  });

  testWidgets('Home 6 — Cars & Maintenance renders live previews and roadside assistance cards', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const CarsMaintenanceHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('معاينات حية'), findsOneWidget);
    expect(find.text('السيارات وقطع الغيار'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('عطلان من البنزين؟'), 300);
    expect(find.text('عطلان من البنزين؟'), findsOneWidget);
  });

  testWidgets('Home 7 — Fashion & Accessories renders categories, featured look, and brand cards', (tester) async {
    await tester.pumpWidget(_wrapWithProviders(const FashionAccessoriesHomePage()));
    await tester.pumpAndSettle();

    expect(find.text('الأقسام والفئات'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('الأكثر مبيعاً من أشهر الماركات'), 300);
    expect(find.text('الأكثر مبيعاً من أشهر الماركات'), findsOneWidget);
  });
}
