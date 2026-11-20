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
import 'package:market_space/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:market_space/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:market_space/features/main_hub/presentation/pages/main_hub_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/search/presentation/screens/search_screen.dart';
import 'package:market_space/features/services_engineering/presentation/pages/services_engineering_home_page.dart';

class _MatrixPrefs implements PreferencesService {
  final Map<String, Object> _m = {};
  @override
  Future<void> clear() async => _m.clear();
  @override
  Future<bool?> getBool(String key) async => _m[key] as bool?;
  @override
  Future<double?> getDouble(String key) async => _m[key] as double?;
  @override
  Future<int?> getInt(String key) async => _m[key] as int?;
  @override
  Future<String?> getString(String key) async => _m[key] as String?;
  @override
  Future<void> remove(String key) async => _m.remove(key);
  @override
  Future<void> setBool(String key, bool value) async => _m[key] = value;
  @override
  Future<void> setDouble(String key, double value) async => _m[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _m[key] = value;
  @override
  Future<void> setString(String key, String value) async => _m[key] = value;
}

class _MatrixNetworkInfo implements NetworkInfo {
  final bool online;
  _MatrixNetworkInfo({this.online = true});
  @override
  Future<bool> get isConnected async => online;
  @override
  Stream<bool> get onConnectivityChanged => Stream.value(online);
}

class _MatrixApiClient implements ApiClient {
  final bool longStrings;
  _MatrixApiClient({this.longStrings = false});

  Map<String, dynamic> _item(String id, String slug, double price) {
    final title = longStrings
        ? 'شقة دوبلكس فندقية سوبر لوكس بواجهة بحرية مفتوحة على الحديقة المركزية بالتجمع الخامس'
        : 'إعلان مميز $slug';
    final seller = longStrings
        ? 'مجموعة شركات الأهرام للتطوير العقاري والهندسي المتكامل والمقاولات'
        : 'شركة ديل ون المعتمدة';
    return {
      'id': id,
      'title': title,
      'description': longStrings
          ? 'وصف طويل جداً لاختبار التفاف النصوص وعدم حدوث أي قص أو تجاوز في البطاقات على الشاشات الصغيرة وعند تكبير الخط حتى ضعف الحجم الطبيعي 2.0x.'
          : 'وصف تفصيلي للمنتج من الخادم',
      'price': price,
      'currency': 'EGP',
      'condition': 'NEW',
      'listingKind': slug.contains('rent') ? 'rent' : 'sale',
      'categoryId': 'cat-$slug',
      'category': {
        'id': 'cat-$slug',
        'slug': slug,
        'nameAr': longStrings ? 'تصنيف فرعي طويل للاختبار' : 'قسم $slug',
        'nameEn': 'Category $slug',
      },
      'governorateName': 'الغربية',
      'cityName': 'طنطا',
      'areaName': 'شارع النادي الرئيسي',
      'media': const [],
      'attributes': {
        'rooms': 4,
        'baths': 3,
        'area_sqm': 245,
        'finishing': 'ألترا سوبر لوكس',
        'floor': 5,
        'year': 2026,
        'transmission': 'أوتوماتيك',
        'fuel_type': 'بنزين / هجين',
        'brand': 'TOSHIBA',
        'unit_of_measure': 'طن',
      },
      'viewsCount': 1420,
      'favoritesCount': 38,
      'sellerName': seller,
      'sellerType': 'company',
      'isVerified': true,
      'isFeatured': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

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
        data: {
          'success': true,
          'data': [
            {'id': 'fav-1', 'listing': _item('l-fav', 'real-estate', 3200000)},
          ],
        } as T,
      );
    }

    if (path.startsWith('/listings/')) {
      final id = path.replaceFirst('/listings/', '');
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {'success': true, 'data': _item(id, 'real-estate', 4500000)} as T,
      );
    }

    if (path == '/categories') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': [
            {
              'id': '1',
              'slug': 'real-estate',
              'nameAr': 'عقارات وأراضٍ',
              'nameEn': 'Real Estate',
              'listingsCount': 60,
              'children': [
                {
                  'id': '11',
                  'slug': 'apartments-for-sale',
                  'nameAr': 'شقق للبيع',
                  'nameEn': 'Apartments for Sale',
                  'listingsCount': 30,
                },
              ],
            },
          ],
        } as T,
      );
    }

    if (path == '/search') {
      return Response<T>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'success': true,
          'data': [
            _item('s-1', 'real-estate', 2800000),
            _item('s-2', 'cars', 1650000),
            _item('s-3', 'home-appliances', 32500),
            _item('s-4', 'fashion', 1850),
          ],
          'meta': {
            'total': 4,
            'page': 1,
            'limit': 20,
            'totalPages': 2,
            'query': '',
          },
        } as T,
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
              {'id': '2', 'slug': 'home-appliances', 'nameAr': 'أجهزة وديكور', 'nameEn': 'Appliances & Decor', 'listingsCount': 60},
              {'id': '3', 'slug': 'services', 'nameAr': 'خدمات وهندسة', 'nameEn': 'Services & Engineering', 'listingsCount': 60},
              {'id': '4', 'slug': 'building-materials', 'nameAr': 'مواد بناء وكهرباء', 'nameEn': 'Building Materials', 'listingsCount': 60},
              {'id': '5', 'slug': 'cars', 'nameAr': 'سيارات وصيانة', 'nameEn': 'Cars & Maintenance', 'listingsCount': 50},
              {'id': '6', 'slug': 'fashion', 'nameAr': 'أزياء وإكسسوارات', 'nameEn': 'Fashion & Accessories', 'listingsCount': 50},
            ],
            'promotions': [
              {
                'id': 'p1',
                'badgeAr': 'خامات التأسيس',
                'badgeEn': 'Construction Essentials',
                'titleAr': 'ابنِ بيتك على أساس متين',
                'titleEn': 'Build Your Home on a Solid Foundation',
                'subtitleAr': 'حديد، إسمنت، طوب وكافة مواد البناء بأعلى جودة',
                'subtitleEn': 'Steel, cement, bricks & building materials',
                'ctaAr': 'تصفح المواد',
                'ctaEn': 'Browse Materials',
                'categorySlug': 'building-materials',
                'imageUrl': '',
              },
            ],
            'featured': [
              _item('f1', 'apartments-for-sale', 3200000),
              _item('f2', 'cars-for-sale', 1850000),
            ],
            'latest': [
              _item('l1', 'ac-maintenance', 350),
              _item('l2', 'steel-rebar', 38500),
              _item('l3', 'mens-clothing', 1500),
              _item('l4', 'refrigerators-freezers', 32500),
            ],
            'recommended': [
              _item('r1', 'ac-maintenance', 250),
              _item('r2', 'steel-rebar', 38500),
              _item('r3', 'apartments-for-rent', 14000),
              _item('r4', 'womens-clothing', 2400),
            ],
          },
        } as T,
      );
    }

    if (path.startsWith('/home/sections/')) {
      final slug = path.replaceFirst('/home/sections/', '');
      final items = [
        _item('sec-$slug-1', slug, 150000),
        _item('sec-$slug-2', slug, 280000),
        _item('sec-$slug-3', slug, 95000),
        _item('sec-$slug-4', slug, 420000),
      ];
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
              'nameEn': 'Section $slug',
              'listingsCount': 60,
              'subcategories': [
                {'id': 'sub-1', 'slug': '$slug-sub1', 'nameAr': 'تصنيف فرعي أول', 'nameEn': 'Subcategory One', 'listingsCount': 20},
                {'id': 'sub-2', 'slug': '$slug-sub2', 'nameAr': 'تصنيف فرعي ثانٍ', 'nameEn': 'Subcategory Two', 'listingsCount': 20},
                {'id': 'sub-3', 'slug': '$slug-decor', 'nameAr': 'ديكور وأثاث منزلي', 'nameEn': 'Home Decor & Furniture', 'listingsCount': 10},
                {'id': 'sub-4', 'slug': '$slug-electrical', 'nameAr': 'كهرباء وتأسيس', 'nameEn': 'Electrical & Wiring', 'listingsCount': 10},
              ],
            },
            'promotions': [
              {
                'id': 'sp1',
                'badgeAr': 'عرض اليوم',
                'badgeEn': 'Deal of the Day',
                'titleAr': 'خصومات حصرية تصل إلى 30% في قسم $slug',
                'titleEn': 'Up to 30% Off Exclusive Deals',
                'subtitleAr': 'أفضل الأسعار من الموردين والوكلاء المعتمدين مع ضمان شامل',
                'subtitleEn': 'Verified sellers with full official warranty',
                'ctaAr': 'تصفح العروض',
                'ctaEn': 'Browse Deals',
                'categorySlug': slug,
                'imageUrl': '',
              },
            ],
            'livePreviews': [
              {
                'listingId': 'sec-$slug-1',
                'title': longStrings
                    ? 'معاينة حية لشقة دوبلكس 240م في التجمع الخامس'
                    : 'معاينة حية $slug',
                'price': 2500000,
                'currency': 'EGP',
                'imageUrl': '',
                'mediaCount': 5,
                'sellerName': 'أحمد العقارية',
                'isVerified': true,
              },
              {
                'listingId': 'sec-$slug-2',
                'title': 'معاينة ثانية $slug',
                'price': 4200000,
                'currency': 'EGP',
                'imageUrl': '',
                'mediaCount': 8,
                'sellerName': 'أوتو إيليت',
                'isVerified': true,
              },
            ],
            'featured': items,
            'latest': items,
            'recommended': items,
            'providers': [
              {
                'id': 'prov-1',
                'displayName': longStrings
                    ? 'شركة الصفا الهندسية للتكييف والتبريد والمقاولات المتكاملة'
                    : 'شركة الصفا المعتمدة',
                'slug': 'safa',
                'accountType': 'company',
                'isVerified': true,
                'specialtyAr': 'وكالة معتمدة - صيانة ومبيعات وتوريد',
                'specialtyEn': 'Certified Partner - Sales & Maintenance',
                'listingsCount': 120,
              },
            ],
            'filterConfig': {
              'sectionSlug': slug,
              'supportsPriceRange': true,
              'supportsLocation': true,
              'supportsCondition': true,
              'supportsListingKind': slug == 'real-estate' || slug == 'cars',
              'listingKindOptions': [
                {'value': 'sale', 'labelAr': 'للبيع', 'labelEn': 'For Sale'},
                {'value': 'rent', 'labelAr': 'للإيجار', 'labelEn': 'For Rent'},
              ],
              'sortOptions': [
                {'value': 'newest', 'labelAr': 'الأحدث', 'labelEn': 'Newest'},
                {'value': 'price_asc', 'labelAr': 'الأقل سعراً', 'labelEn': 'Lowest Price'},
              ],
              'fields': [
                {'key': 'rooms', 'labelAr': 'عدد الغرف', 'labelEn': 'Rooms', 'type': 'number', 'options': [], 'sortOrder': 1},
                {'key': 'finishing', 'labelAr': 'التشطيب', 'labelEn': 'Finishing', 'type': 'select', 'options': ['سوبر لوكس', 'نصف تشطيب'], 'sortOrder': 2},
                {'key': 'furnished', 'labelAr': 'مفروش', 'labelEn': 'Furnished', 'type': 'boolean', 'options': [], 'sortOrder': 3},
              ],
            },
          },
        } as T,
      );
    }

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {
        'success': true,
        'data': [
          _item('list-1', 'real-estate', 900000),
          _item('list-2', 'cars', 650000),
          _item('list-3', 'fashion', 1200),
          _item('list-4', 'services', 400),
        ],
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

const List<(String, Size)> kDeviceViewportMatrix = [
  ('Small Phone (320x568)', Size(320, 568)),
  ('Compact Android (360x640)', Size(360, 640)),
  ('Standard Android (360x800)', Size(360, 800)),
  ('Modern Android (393x873)', Size(393, 873)),
  ('Large Android (412x915)', Size(412, 915)),
  ('Large Phone (440x956)', Size(440, 956)),
  ('Small Tablet (600x960)', Size(600, 960)),
  ('Tablet (768x1024)', Size(768, 1024)),
  ('Large Tablet (1024x1366)', Size(1024, 1366)),
];

Widget buildResponsiveTestApp({
  required Widget child,
  TextDirection direction = TextDirection.rtl,
  double textScale = 1.0,
  bool longStrings = false,
  bool online = true,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  final prefs = _MatrixPrefs();
  final api = _MatrixApiClient(longStrings: longStrings);
  final cache = HybridCacheManager(preferencesService: prefs);

  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      networkInfoProvider.overrideWithValue(_MatrixNetworkInfo(online: online)),
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
      debugShowCheckedModeBanner: false,
      builder: (context, appChild) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: Directionality(
            textDirection: direction,
            child: appChild!,
          ),
        );
      },
      home: child,
    ),
  );
}

Future<void> _pumpOnViewport(
  WidgetTester tester, {
  required Size size,
  required Widget screen,
  TextDirection direction = TextDirection.rtl,
  double textScale = 1.0,
  bool longStrings = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool scrollTest = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    buildResponsiveTestApp(
      child: screen,
      direction: direction,
      textScale: textScale,
      longStrings: longStrings,
      viewInsets: viewInsets,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);

  if (scrollTest) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  }
}

void main() {
  final homes = <(String, Widget Function())>[
    ('Home 1 - Main Hub', () => const MainHubPage()),
    ('Home 2 - Real Estate & Land', () => const RealEstateHomePage()),
    ('Home 3 - Appliances & Decor', () => const AppliancesDecorHomePage()),
    ('Home 4 - Services & Engineering', () => const ServicesEngineeringHomePage()),
    ('Home 5 - Construction & Electrical', () => const ConstructionElectricalHomePage()),
    ('Home 6 - Cars & Maintenance', () => const CarsMaintenanceHomePage()),
    ('Home 7 - Fashion & Accessories', () => const FashionAccessoriesHomePage()),
  ];

  group('Phase 5 & 9 — 9-Device Viewport Matrix Audit (320x568 up to 1024x1366)', () {
    for (final (homeName, builder) in homes) {
      testWidgets('$homeName renders without overflow across all 9 device viewports (Portrait & Landscape)', (tester) async {
        for (final (_, size) in kDeviceViewportMatrix) {
          await _pumpOnViewport(tester, size: size, screen: builder());
        }
        // Also test Landscape on Phone (800x360) and Tablet (1024x768)
        await _pumpOnViewport(
          tester,
          size: const Size(800, 360),
          screen: builder(),
        );
        await _pumpOnViewport(
          tester,
          size: const Size(1024, 768),
          screen: builder(),
        );
      });
    }
  });

  group('Phase 7 & 11 — Typography Scaling (1.0x, 1.3x, 1.6x, 2.0x) + Long Content + RTL/LTR Audit', () {
    for (final (homeName, builder) in homes) {
      testWidgets('$homeName handles 2.0x text scale + long strings on 320x568 Small Phone & 393x873 in RTL and LTR', (tester) async {
        // 320x568 Small Phone at 2.0x text scale with extra-long Arabic strings (RTL)
        await _pumpOnViewport(
          tester,
          size: const Size(320, 568),
          screen: builder(),
          direction: TextDirection.rtl,
          textScale: 2.0,
          longStrings: true,
        );

        // 393x873 Modern Android at 1.6x text scale in English (LTR)
        await _pumpOnViewport(
          tester,
          size: const Size(393, 873),
          screen: builder(),
          direction: TextDirection.ltr,
          textScale: 1.6,
          longStrings: true,
        );
      });
    }
  });

  group('Phase 8 & 10 — Shared Screens, Filter Bottom Sheet & Keyboard Insets Audit', () {
    testWidgets('SearchScreen, ListingDetailScreen, and FavoritesScreen render cleanly across 320x568 (2.0x scale) and 1024x1366 Tablet', (tester) async {
      for (final screen in [
        const SearchScreen(),
        const ListingDetailScreen(listingId: 'l-1'),
        const FavoritesScreen(),
      ]) {
        await _pumpOnViewport(
          tester,
          size: const Size(320, 568),
          screen: screen,
          textScale: 2.0,
          longStrings: true,
        );
        await _pumpOnViewport(
          tester,
          size: const Size(1024, 1366),
          screen: screen,
          direction: TextDirection.ltr,
        );
      }
    });

    testWidgets('Server-Driven Filter Sheet remains usable with soft keyboard open (viewInsets.bottom = 280) on 320x568', (tester) async {
      await _pumpOnViewport(
        tester,
        size: const Size(320, 568),
        screen: const RealEstateHomePage(),
        viewInsets: const EdgeInsets.only(bottom: 280),
        scrollTest: false,
      );

      final filterIcon = find.byIcon(Icons.filter_alt_rounded);
      expect(filterIcon, findsOneWidget);
      await tester.tap(filterIcon);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('تطبيق الفلاتر'), findsOneWidget);
    });
  });
}
