import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/maps/data/models/map_place_mapper.dart';
import 'package:market_space/features/maps/domain/entities/map_bounds.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/maps/domain/entities/map_cluster.dart';
import 'package:market_space/features/maps/domain/entities/map_place_entity.dart';
import 'package:market_space/features/maps/presentation/providers/category_map_provider.dart';
import 'package:market_space/features/maps/presentation/widgets/map_current_location_button.dart';
import 'package:market_space/features/maps/presentation/widgets/map_filters.dart';
import 'package:market_space/features/maps/presentation/widgets/map_markers.dart';
import 'package:market_space/features/maps/presentation/widgets/map_place_preview.dart';
import 'package:market_space/features/maps/presentation/widgets/map_search_bar.dart';

/// Universal Category Map screen shared across all 6 Deal One categories.
/// One reusable architecture and UI, six distinct data & filter contexts.
class CategoryMapPage extends ConsumerStatefulWidget {
  final String categorySlug;
  final ListingItem? focusedListing;
  final bool showBottomNavigation;

  const CategoryMapPage({
    super.key,
    required this.categorySlug,
    this.focusedListing,
    this.showBottomNavigation = true,
  });

  @override
  ConsumerState<CategoryMapPage> createState() => _CategoryMapPageState();
}

class _CategoryMapPageState extends ConsumerState<CategoryMapPage> {
  final MapController _mapController = MapController();
  late final TextEditingController _searchController;

  String get _normalizedSlug =>
      MapCategoryRegistry.normalizeSlug(widget.categorySlug);

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(
      categoryMapControllerProvider(_normalizedSlug),
    );
    _searchController = TextEditingController(text: initialState.searchQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusedPlace = widget.focusedListing != null
          ? MapPlaceMapper.fromListingEntity(widget.focusedListing!)
          : null;
      ref
          .read(categoryMapControllerProvider(_normalizedSlug).notifier)
          .ensureInitialized(focusedPlace: focusedPlace);
    });
  }

  @override
  void didUpdateWidget(covariant CategoryMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug) {
      final nextState = ref.read(
        categoryMapControllerProvider(_normalizedSlug),
      );
      _searchController.text = nextState.searchQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(categoryMapControllerProvider(_normalizedSlug).notifier)
            .ensureInitialized();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _safeMove(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      // MapController may not be attached yet during initial frame or tests.
    }
  }

  void _zoomBy(double delta, CategoryMapState state) {
    final nextZoom = (state.cameraZoom + delta).clamp(5.0, 18.0);
    _safeMove(state.cameraCenter, nextZoom);
    ref
        .read(categoryMapControllerProvider(_normalizedSlug).notifier)
        .onCameraChanged(
          center: state.cameraCenter,
          zoom: nextZoom,
          bounds: state.visibleBounds,
        );
  }

  void _onClusterTap(MapMarkerCluster cluster, CategoryMapState state) {
    final nextZoom = (state.cameraZoom + 2.0).clamp(5.0, 18.0);
    _safeMove(cluster.center, nextZoom);
    ref
        .read(categoryMapControllerProvider(_normalizedSlug).notifier)
        .onCameraChanged(
          center: cluster.center,
          zoom: nextZoom,
          bounds: state.visibleBounds,
        );
  }

  Future<void> _handleCurrentLocationTap(CategoryMapState state) async {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    // Ask user with clear rationale before requesting location or sharing
    // coordinates with the backend.
    final consent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic ? 'استخدام موقعك الحالي' : 'Use Your Current Location',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          isArabic
              ? 'نحتاج صلاحية الموقع لتحديد مكانك على الخريطة وإظهار أقرب ${state.config.subtitleAr} لك. يمكنك المتابعة بالبحث اليدوي في أي وقت إذا رفضت.'
              : 'We use your location to center the map and find nearby ${state.config.subtitleEn}. You can continue browsing manually if you decline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isArabic ? 'لاحقاً' : 'Not Now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'متابعة' : 'Continue'),
          ),
        ],
      ),
    );

    if (consent != true || !mounted) return;

    final result = await ref
        .read(categoryMapControllerProvider(_normalizedSlug).notifier)
        .requestCurrentLocation(consentedToNearbySearch: true);

    if (!mounted) return;
    if (result.coordinates != null) {
      _safeMove(result.coordinates!, 13.5);
    } else {
      final msg = isArabic
          ? (result.messageAr ?? 'تعذر تحديد الموقع الحالي.')
          : (result.messageEn ?? 'Could not determine current location.');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _openAdvancedFilters(CategoryMapState state) async {
    final result = await showMapAdvancedFiltersSheet(
      context: context,
      config: state.config,
      verifiedOnly: state.verifiedOnly,
      searchAllCategories: state.searchAllCategories,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
    );
    if (result == null || !mounted) return;
    final notifier = ref.read(
      categoryMapControllerProvider(_normalizedSlug).notifier,
    );
    if (result.reset) {
      _searchController.clear();
      await notifier.resetFilters();
    } else {
      await notifier.applyAdvancedFilters(
        verifiedOnly: result.verifiedOnly,
        searchAllCategories: result.searchAllCategories,
        minPrice: result.minPrice,
        clearMinPrice: result.minPrice == null,
        maxPrice: result.maxPrice,
        clearMaxPrice: result.maxPrice == null,
      );
    }
  }

  Future<void> _openDirections(MapPlaceEntity place) async {
    final url = place.directionsUrl;
    if (url == null) return;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تم نسخ رابط الاتجاهات (${place.latitude!.toStringAsFixed(4)}, ${place.longitude!.toStringAsFixed(4)})'
              : 'Directions link copied (${place.latitude!.toStringAsFixed(4)}, ${place.longitude!.toStringAsFixed(4)})',
        ),
      ),
    );
  }

  Future<void> _startChatWithSeller(MapPlaceEntity place) async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      context.push(RouteNames.login);
      return;
    }
    try {
      final conv = await ref
          .read(conversationsRepositoryProvider)
          .startOrGetConversation(place.id, currentUserId: session.userId);
      if (mounted) {
        context.push('/conversations/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openPlaceDetails(MapPlaceEntity place) {
    if (_normalizedSlug == MapCategoryRegistry.realEstateSlug &&
        place.sourceListing != null) {
      context.push(
        '${RouteNames.realEstateDetail}?id=${place.id}',
        extra: place.sourceListing,
      );
      return;
    }
    context.push('/listings/${place.id}');
  }

  void _showAreaResultsSheet(CategoryMapState state) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final items = state.filteredPlaces;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: DealOneTokens.cardSurfaceOf(ctx),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DealOneTokens.cardBorderOf(ctx),
                      borderRadius: AppRadii.full,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isArabic
                                ? '${state.config.titleAr} (${items.length})'
                                : '${state.config.titleEn} (${items.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: DealOneTokens.textPrimaryOf(ctx),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final place = items[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                            side: BorderSide(
                              color: DealOneTokens.cardBorderOf(ctx),
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: state.config.accentColor
                                .withValues(alpha: 0.12),
                            child: Icon(
                              state.config.markerIcon,
                              color: state.config.accentColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            place.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            place.formattedAddress(isArabic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: place.price > 0
                              ? Text(
                                  formatDealOnePrice(
                                    place.price,
                                    currency: place.currency,
                                    isArabic: isArabic,
                                  ),
                                  style: const TextStyle(
                                    color: DealOneTokens.amber,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ref
                                .read(
                                  categoryMapControllerProvider(
                                    _normalizedSlug,
                                  ).notifier,
                                )
                                .selectPlace(place);
                            if (place.point != null) {
                              _safeMove(place.point!, state.cameraZoom);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(categoryMapControllerProvider(_normalizedSlug));
    final notifier = ref.read(
      categoryMapControllerProvider(_normalizedSlug).notifier,
    );
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;

    final clusters = state.visibleClusters;
    final markers = DealOneMapMarkers.buildMarkers(
      context: context,
      clusters: clusters,
      defaultConfig: state.config,
      selectedPlaceId: state.selectedPlace?.id,
      isArabic: isArabic,
      userLocation: state.userLocation.coordinates,
      onPlaceTap: (place) {
        // Select marker cleanly without reloading the map!
        notifier.selectPlace(place);
        if (place.point != null) {
          _safeMove(place.point!, state.cameraZoom);
        }
      },
      onClusterTap: (cluster) => _onClusterTap(cluster, state),
    );

    final bottomPreviewOffset = widget.showBottomNavigation ? 96.0 : 16.0;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      extendBody: widget.showBottomNavigation,
      bottomNavigationBar: widget.showBottomNavigation
          ? DealOneSectionBottomNav(
              sectionId: _normalizedSlug,
              activeTabId: SectionNavigationRegistry.mapTabId,
            )
          : null,
      body: Stack(
        children: [
          // 1. Interactive FlutterMap Layer
          if (state.isLoading && !state.hasInitialized && state.places.isEmpty)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (state.error != null && state.places.isEmpty)
            DealOneErrorStateView(
              error: state.error!,
              onRetry: () => notifier.fetchPlaces(resetPage: true),
            )
          else
            FlutterMap(
              key: Key('category_flutter_map_$_normalizedSlug'),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: state.cameraCenter,
                initialZoom: state.cameraZoom,
                onTap: (_, _) {
                  if (state.selectedPlace != null) {
                    notifier.selectPlace(null);
                  }
                },
                onPositionChanged: (camera, hasGesture) {
                  if (!hasGesture) return;
                  final bounds = camera.visibleBounds;
                  notifier.onCameraChanged(
                    center: camera.center,
                    zoom: camera.zoom,
                    bounds: MapBoundingBox(
                      south: bounds.south,
                      west: bounds.west,
                      north: bounds.north,
                      east: bounds.east,
                    ),
                  );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: state.useAlternateTileStyle
                      ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.dealone.marketspace',
                ),
                MarkerLayer(markers: markers),
              ],
            ),

          // 2. Floating Top Context Header + Search Bar + Filters + Status Banners
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xs, hPad, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Context Pill Header
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: state.config.accentColor,
                            borderRadius: AppRadii.full,
                            boxShadow: DealOneTokens.cardShadow(context),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.config.markerIcon,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  state.searchAllCategories
                                      ? (isArabic
                                            ? 'جميع أقسام Deal One'
                                            : 'All Deal One Categories')
                                      : state.config.localizedTitle(isArabic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (state.isLoading)
                        Container(
                          width: 28,
                          height: 28,
                          padding: const EdgeInsets.all(6),
                          decoration: DealOneTokens.cardDecoration(
                            context,
                            borderRadius: AppRadii.full,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Search Bar
                  MapSearchBar(
                    controller: _searchController,
                    hintText: state.config.localizedSearchHint(isArabic),
                    activeFilterCount: state.activeFilterCount,
                    onBackTap: !widget.showBottomNavigation && context.canPop()
                        ? () => context.pop()
                        : null,
                    onChanged: notifier.setSearchQuery,
                    onSubmitted: notifier.submitSearch,
                    onClear: () {
                      _searchController.clear();
                      notifier.submitSearch('');
                    },
                    onFilterTap: () => _openAdvancedFilters(state),
                    onLayerToggle: notifier.toggleTileStyle,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Category-specific Quick Filters + All Categories opt-in
                  MapFiltersBar(
                    config: state.config,
                    activeFilterId: state.activeFilterId,
                    searchAllCategories: state.searchAllCategories,
                    onFilterSelected: notifier.selectQuickFilter,
                    onSearchAllToggled: notifier.toggleSearchAllCategories,
                  ),

                  // "Search This Area" CTA after significant viewport pan
                  if (state.hasPendingAreaSearch && !state.isLoading) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: ElevatedButton.icon(
                        key: const Key('map_search_this_area_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DealOneTokens.navy,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.full,
                          ),
                        ),
                        onPressed: notifier.searchInVisibleArea,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          isArabic ? 'ابحث في هذه المنطقة' : 'Search this area',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Offline banner
                  if (isOffline) ...[
                    const SizedBox(height: AppSpacing.xs),
                    DealOneOfflineBanner(
                      onRetry: () => notifier.fetchPlaces(resetPage: true),
                    ),
                  ],

                  // Location permission denied / unavailable banner (non-blocking)
                  if (state.userLocation.isDeniedOrUnavailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      key: const Key('map_location_denied_banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: DealOneTokens.dangerSoftBg,
                        borderRadius: AppRadii.md,
                      ),
                      child: Text(
                        isArabic
                            ? 'صلاحية الموقع غير مفعلة — يمكنك تصفح الخريطة والبحث يدوياً.'
                            : 'Location permission denied — you can still pan and search manually.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: DealOneTokens.dangerRed,
                        ),
                      ),
                    ),
                  ],

                  // Honest backend coordinate notice when real items exist without GPS pins
                  if (state.hasInitialized &&
                      !state.isLoading &&
                      state.mappablePlaces.isEmpty &&
                      state.unmappedPlaces.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: () => _showAreaResultsSheet(state),
                      borderRadius: AppRadii.md,
                      child: Container(
                        key: const Key('map_unmapped_results_banner'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DealOneTokens.amberTintOf(context),
                          borderRadius: AppRadii.md,
                          border: Border.all(color: DealOneTokens.amberBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: DealOneTokens.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'تم العثور على ${state.unmappedPlaces.length} نتيجة بدون إحداثيات GPS مرفقة من الخادم — اضغط للعرض.'
                                    : '${state.unmappedPlaces.length} results found without GPS coordinates in API response — tap to view.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: DealOneTokens.navy,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: DealOneTokens.navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Empty state notice when no results exist in current scope
                  if (state.hasInitialized &&
                      !state.isLoading &&
                      state.error == null &&
                      state.filteredPlaces.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      key: const Key('map_empty_state_banner'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: DealOneTokens.cardDecoration(
                        context,
                        borderRadius: AppRadii.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.config.markerIcon,
                            size: 18,
                            color: state.config.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.config.localizedEmptyMessage(isArabic),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DealOneTokens.textPrimaryOf(context),
                              ),
                            ),
                          ),
                          if (state.activeFilterCount > 0 ||
                              state.searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                notifier.resetFilters();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isArabic ? 'مسح' : 'Reset',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls (Current Location, Recenter, Zoom +/-)
          PositionedDirectional(
            end: hPad,
            top: MediaQuery.sizeOf(context).height * 0.34,
            child: MapCurrentLocationControls(
              locationStatus: state.userLocation.status,
              onMyLocationTap: () => _handleCurrentLocationTap(state),
              onRecenterTap: () {
                final target =
                    state.selectedPlace?.point ??
                    state.userLocation.coordinates ??
                    (state.mappablePlaces.isNotEmpty
                        ? state.mappablePlaces.first.point!
                        : kDefaultEgyptMapCenter);
                _safeMove(target, 12.5);
              },
              onZoomIn: () => _zoomBy(1.0, state),
              onZoomOut: () => _zoomBy(-1.0, state),
            ),
          ),

          // 4. Animated Bottom Place Preview Card
          if (state.selectedPlace != null)
            Positioned(
              left: hPad,
              right: hPad,
              bottom: bottomPreviewOffset,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: MapPlacePreviewCard(
                    key: ValueKey(state.selectedPlace!.id),
                    place: state.selectedPlace!,
                    config: state.selectedPlace!.categorySlug.isNotEmpty
                        ? MapCategoryRegistry.forSlug(
                            state.selectedPlace!.categorySlug,
                          )
                        : state.config,
                    userLocation: state.userLocation.coordinates,
                    onOpenDetails: () =>
                        _openPlaceDetails(state.selectedPlace!),
                    onDirectionsTap: state.selectedPlace!.hasCoordinates
                        ? () => _openDirections(state.selectedPlace!)
                        : null,
                    onContactSeller: () =>
                        _startChatWithSeller(state.selectedPlace!),
                    onClose: () => notifier.selectPlace(null),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
