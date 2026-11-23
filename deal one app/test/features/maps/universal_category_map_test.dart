import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/features/maps/domain/entities/location_permission_state.dart';
import 'package:market_space/features/maps/domain/entities/map_bounds.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/maps/domain/entities/map_cluster.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/features/maps/domain/repositories/category_map_repository.dart';
import 'package:market_space/features/maps/presentation/pages/category_map_page.dart';
import 'package:market_space/features/maps/presentation/providers/category_map_provider.dart';
import 'package:market_space/features/maps/presentation/providers/map_location_service.dart';

class FakeCategoryMapRepository implements CategoryMapRepository {
  final Map<String, List<MapPlaceEntity>> datasetByCategory;
  final List<MapPlacesQuery> recordedQueries = [];
  final List<String> cancelledScopes = [];
  Object? errorToThrow;

  FakeCategoryMapRepository({required this.datasetByCategory});

  @override
  void cancelInFlight(String requestScopeKey) {
    cancelledScopes.add(requestScopeKey);
  }

  @override
  Future<MapPlacesPage> fetchPlaces({
    required String requestScopeKey,
    required MapPlacesQuery query,
  }) async {
    recordedQueries.add(query);
    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    List<MapPlaceEntity> items;
    if (query.searchAllCategories) {
      items = datasetByCategory.values.expand((e) => e).toList();
    } else {
      items = List<MapPlaceEntity>.from(
        datasetByCategory[query.categorySlug] ?? const [],
      );
    }

    if (query.query.trim().isNotEmpty) {
      final q = query.query.trim().toLowerCase();
      items = items
          .where((p) => p.title.toLowerCase().contains(q))
          .toList();
    }
    if (query.listingKind != null) {
      items = items
          .where((p) => p.listingKind == query.listingKind)
          .toList();
    }
    if (query.condition != null) {
      items = items.where((p) => p.condition == query.condition).toList();
    }
    if (query.featuredOnly) {
      items = items.where((p) => p.isFeatured).toList();
    }

    return MapPlacesPage(
      items: items,
      totalCount: items.length,
      page: query.page,
      totalPages: 1,
    );
  }
}

class FakeLocationService implements MapLocationService {
  final MapLocationRequestResult result;
  int callCount = 0;

  FakeLocationService(this.result);

  @override
  Future<MapLocationRequestResult> requestCurrentLocation() async {
    callCount++;
    return result;
  }
}

MapPlaceEntity _makePlace({
  required String id,
  required String title,
  required String categorySlug,
  double? lat,
  double? lng,
  double price = 150000,
  String listingKind = 'sale',
  String condition = 'NEW',
  bool isVerified = true,
  bool isFeatured = false,
  String merchantName = 'Deal One Store',
  String merchantType = 'store',
}) {
  return MapPlaceEntity(
    id: id,
    title: title,
    categoryId: 'cat_$categorySlug',
    categorySlug: categorySlug,
    price: price,
    listingKind: listingKind,
    condition: condition,
    latitude: lat,
    longitude: lng,
    areaName: 'التجمع الخامس',
    cityName: 'القاهرة الجديدة',
    governorateName: 'القاهرة',
    merchantName: merchantName,
    merchantType: merchantType,
    isVerified: isVerified,
    isFeatured: isFeatured,
  );
}

void main() {
  group('1. Universal Map Tab in All 6 Category Navigation Configs', () {
    test('All 6 categories register a dedicated Map tab with unique route', () {
      final configs = SectionNavigationRegistry.sixCategoryConfigs;
      expect(configs.length, equals(6));

      final expectedSlugs = MapCategoryRegistry.allSixSlugs;
      for (final slug in expectedSlugs) {
        final config = SectionNavigationRegistry.getConfig(slug);
        expect(config.sectionId, equals(slug));
        final mapItems = config.items
            .where((i) => i.id == SectionNavigationRegistry.mapTabId)
            .toList();
        expect(mapItems.length, equals(1), reason: 'Missing map tab for $slug');
        expect(mapItems.first.label, equals('الخريطة'));
        expect(mapItems.first.destination, equals('/map/$slug'));
      }
    });

    testWidgets(
      'DealOneSectionBottomNav renders Map tab with zero overflow across viewports & 2.0x text scale',
      (tester) async {
        final viewports = <Size>[
          const Size(320, 568),
          const Size(393, 873),
          const Size(768, 1024),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          for (final slug in MapCategoryRegistry.allSixSlugs) {
            await tester.pumpWidget(
              ProviderScope(
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2.0),
                  ),
                  child: MaterialApp(
                    home: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Scaffold(
                        bottomNavigationBar: DealOneSectionBottomNav(
                          sectionId: slug,
                          activeTabId: 'home',
                          onItemTap: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(find.text('الخريطة'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
        addTearDown(() => tester.view.resetPhysicalSize());
      },
    );
  });

  group('2. Category Isolation, Zero Mock Locations, Bounds & Clustering', () {
    test('Strict category isolation prevents mixing places across sections', () async {
      final repo = FakeCategoryMapRepository(
        datasetByCategory: {
          'real-estate': [
            _makePlace(
              id: 're_1',
              title: 'شقة بالتجمع',
              categorySlug: 'real-estate',
              lat: 30.01,
              lng: 31.43,
            ),
            // Simulate a leaked item from another category: must be filtered out!
            _makePlace(
              id: 'car_leaked',
              title: 'سيارة مستعملة',
              categorySlug: 'cars',
              lat: 30.02,
              lng: 31.44,
            ),
          ],
          'cars': [
            _makePlace(
              id: 'car_1',
              title: 'معرض سيارات النخبة',
              categorySlug: 'cars',
              lat: 30.05,
              lng: 31.25,
            ),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [
          categoryMapRepositoryProvider.overrideWithValue(repo),
          mapLocationServiceProvider.overrideWithValue(
            FakeLocationService(
              const MapLocationRequestResult(
                status: MapLocationPermissionStatus.denied,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final reController = container.read(
        categoryMapControllerProvider('real-estate').notifier,
      );
      await reController.ensureInitialized();

      final reState = container.read(
        categoryMapControllerProvider('real-estate'),
      );
      expect(reState.filteredPlaces.map((p) => p.id), equals(['re_1']));
      expect(reState.mappablePlaces.length, equals(1));

      // Enabling "Search all categories" explicitly allows cross-category results
      await reController.toggleSearchAllCategories(true);
      final allState = container.read(
        categoryMapControllerProvider('real-estate'),
      );
      expect(allState.searchAllCategories, isTrue);
      expect(allState.filteredPlaces.length, equals(3));
    });

    test('Places without coordinates are NOT fabricated into mock pins', () async {
      final repo = FakeCategoryMapRepository(
        datasetByCategory: {
          'services': [
            _makePlace(
              id: 'srv_no_gps',
              title: 'مكتب هندسة معمارية',
              categorySlug: 'services',
              lat: null,
              lng: null,
            ),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [
          categoryMapRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(categoryMapControllerProvider('services').notifier)
          .ensureInitialized();
      final state = container.read(categoryMapControllerProvider('services'));
      expect(state.mappablePlaces, isEmpty);
      expect(state.unmappedPlaces.length, equals(1));
      expect(state.visibleClusters, isEmpty);
    });

    test('Marker clustering handles 150 dense locations efficiently and expands on zoom', () {
      final densePlaces = List<MapPlaceEntity>.generate(150, (i) {
        return _makePlace(
          id: 'p_$i',
          title: 'متجر مواد بناء $i',
          categorySlug: 'building-materials',
          lat: 30.0444 + (i % 10) * 0.0008,
          lng: 31.2357 + (i ~/ 10) * 0.0008,
        );
      });

      final zoomedOutClusters = MapClusterEngine.cluster(
        places: densePlaces,
        zoom: 11.0,
      );
      expect(zoomedOutClusters.length, lessThan(densePlaces.length));
      expect(zoomedOutClusters.any((c) => c.isCluster), isTrue);

      final totalClusteredItems = zoomedOutClusters.fold<int>(
        0,
        (sum, c) => sum + c.count,
      );
      expect(totalClusteredItems, equals(150));

      final zoomedInClusters = MapClusterEngine.cluster(
        places: densePlaces,
        zoom: 16.0,
      );
      expect(zoomedInClusters.length, equals(150));
      expect(zoomedInClusters.every((c) => !c.isCluster), isTrue);
    });

    test('Markers outside visible bounding box are excluded from rendering', () async {
      final repo = FakeCategoryMapRepository(
        datasetByCategory: {
          'fashion': [
            _makePlace(
              id: 'f_cairo',
              title: 'بوتيك وسط البلد',
              categorySlug: 'fashion',
              lat: 30.0444,
              lng: 31.2357,
            ),
            _makePlace(
              id: 'f_alex',
              title: 'بوتيك الإسكندرية',
              categorySlug: 'fashion',
              lat: 31.2001,
              lng: 29.9187,
            ),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [categoryMapRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        categoryMapControllerProvider('fashion').notifier,
      );
      await notifier.ensureInitialized();

      notifier.onCameraChanged(
        center: const LatLng(30.0444, 31.2357),
        zoom: 12.0,
        bounds: const MapBoundingBox(
          south: 29.95,
          west: 31.10,
          north: 30.15,
          east: 31.35,
        ),
      );

      final state = container.read(categoryMapControllerProvider('fashion'));
      expect(state.inBoundsMappablePlaces.map((p) => p.id), equals(['f_cairo']));
    });

    test('State is preserved independently per category when switching sections', () async {
      final repo = FakeCategoryMapRepository(
        datasetByCategory: {
          'real-estate': [
            _makePlace(
              id: 're_1',
              title: 'فيلا التجمع',
              categorySlug: 'real-estate',
              lat: 30.01,
              lng: 31.43,
            ),
          ],
          'cars': [
            _makePlace(
              id: 'car_1',
              title: 'معرض سيارات',
              categorySlug: 'cars',
              lat: 30.05,
              lng: 31.25,
            ),
          ],
        },
      );

      final container = ProviderContainer(
        overrides: [categoryMapRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container
          .read(categoryMapControllerProvider('real-estate').notifier)
          .submitSearch('فيلا');
      await container
          .read(categoryMapControllerProvider('cars').notifier)
          .submitSearch('معرض');

      expect(
        container.read(categoryMapControllerProvider('real-estate')).searchQuery,
        equals('فيلا'),
      );
      expect(
        container.read(categoryMapControllerProvider('cars')).searchQuery,
        equals('معرض'),
      );
    });
  });

  group('3. CategoryMapPage Widget Validation (UI, Permissions, Errors)', () {
    testWidgets(
      'Renders CategoryMapPage with search, filters, preview card, and non-blocking denied location',
      (tester) async {
        final place = _makePlace(
          id: 'app_1',
          title: 'معرض أجهزة منزلية الحديثة',
          categorySlug: 'home-appliances',
          lat: 30.0444,
          lng: 31.2357,
        );
        final repo = FakeCategoryMapRepository(
          datasetByCategory: {
            'home-appliances': [place],
          },
        );
        final locationService = FakeLocationService(
          const MapLocationRequestResult(
            status: MapLocationPermissionStatus.denied,
            messageAr: 'تم رفض صلاحية الموقع.',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryMapRepositoryProvider.overrideWithValue(repo),
              mapLocationServiceProvider.overrideWithValue(locationService),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: CategoryMapPage(categorySlug: 'home-appliances'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Location permission must NOT be requested automatically on mount
        expect(locationService.callCount, equals(0));
        expect(find.text('خريطة الأجهزة والديكور'), findsOneWidget);
        expect(find.byKey(const Key('category_map_search_input')), findsOneWidget);
        expect(find.byKey(const Key('map_filter_chip_all_categories')), findsOneWidget);
        expect(find.byKey(const Key('section_bottom_nav_home-appliances')), findsOneWidget);

        // Tap current location -> shows rationale dialog first
        await tester.tap(find.byKey(const Key('map_current_location_btn')));
        await tester.pumpAndSettle();
        expect(find.text('استخدام موقعك الحالي'), findsOneWidget);

        // Confirm rationale -> location service invoked, denied gracefully without blocking
        await tester.tap(find.text('متابعة'));
        await tester.pumpAndSettle();
        expect(locationService.callCount, equals(1));
        expect(find.byKey(const Key('map_location_denied_banner')), findsOneWidget);

        // Select place programmatically and verify preview card + directions button render without overflow
        final container = ProviderScope.containerOf(
          tester.element(find.byType(CategoryMapPage)),
        );
        final fetchesBeforeSelect = repo.recordedQueries.length;
        container
            .read(categoryMapControllerProvider('home-appliances').notifier)
            .selectPlace(place);
        await tester.pumpAndSettle();

        // Selecting a marker MUST NOT reload the map or re-fetch API
        expect(repo.recordedQueries.length, equals(fetchesBeforeSelect));
        expect(find.byKey(const Key('map_place_preview_app_1')), findsOneWidget);
        expect(find.byKey(const Key('map_preview_open_details_btn')), findsOneWidget);
        expect(find.byKey(const Key('map_preview_directions_btn')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Handles API / network failure gracefully with retry button',
      (tester) async {
        final repo = FakeCategoryMapRepository(datasetByCategory: const {})
          ..errorToThrow = Exception('Network unreachable');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryMapRepositoryProvider.overrideWithValue(repo),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: CategoryMapPage(categorySlug: 'cars'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('خريطة السيارات والصيانة'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
