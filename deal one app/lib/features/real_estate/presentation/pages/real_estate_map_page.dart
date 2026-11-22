import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/marketplace/section_home_controller.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/real_estate/presentation/widgets/map_floating_controls.dart';
import 'package:market_space/features/real_estate/presentation/widgets/map_property_preview_card.dart';

/// Real Estate Map View Screen matching `Map View.png`.
/// Displays real property listings with backend coordinates via `flutter_map`.
class RealEstateMapPage extends ConsumerStatefulWidget {
  final ListingItem? focusedProperty;

  const RealEstateMapPage({super.key, this.focusedProperty});

  @override
  ConsumerState<RealEstateMapPage> createState() => _RealEstateMapPageState();
}

class _RealEstateMapPageState extends ConsumerState<RealEstateMapPage> {
  static const LatLng _defaultEgyptCenter = LatLng(30.7865, 31.0004); // Tanta
  final MapController _mapController = MapController();

  ListingItem? _selectedProperty;
  String _activeFilter = 'all';
  double _currentZoom = 13.5;
  bool _locationPermissionDenied = false;
  bool _useAlternateTileStyle = false;

  @override
  void initState() {
    super.initState();
    _selectedProperty = widget.focusedProperty;
  }

  LatLng? _coordinatesOf(ListingItem item) {
    if (item.latitude != null && item.longitude != null) {
      return LatLng(item.latitude!, item.longitude!);
    }
    return null;
  }

  void _zoomBy(double delta) {
    final next = (_currentZoom + delta).clamp(5.0, 18.0);
    setState(() => _currentZoom = next);
    _mapController.move(_mapController.camera.center, next);
  }

  void _handleLocationPermissionTap() {
    setState(() => _locationPermissionDenied = true);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'يرجى تفعيل صلاحية الموقع من إعدادات الجهاز لتحديد موقعك الحالي.'
              : 'Enable location permission in device settings to center on your location.',
        ),
      ),
    );
  }

  Future<void> _startChatWithSeller(ListingItem property) async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      context.push(RouteNames.login);
      return;
    }
    try {
      final conv = await ref
          .read(conversationsRepositoryProvider)
          .startOrGetConversation(
            property.id,
            currentUserId: session.userId,
          );
      if (mounted) {
        context.push('/conversations/${conv.id}', extra: conv);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final homeState = ref.watch(
      sectionHomeControllerProvider(RealEstateHomePage.sectionSlug),
    );

    final allListings = <ListingItem>[
      if (widget.focusedProperty != null) widget.focusedProperty!,
      ...homeState.listings.where((l) => l.id != widget.focusedProperty?.id),
    ];

    final filteredListings = allListings.where((item) {
      if (_activeFilter == 'rent') {
        return item.listingKind.toLowerCase() == 'rent' ||
            item.categorySlug.contains('rent');
      }
      if (_activeFilter == 'sale') {
        return item.listingKind.toLowerCase() != 'rent' &&
            !item.categorySlug.contains('rent');
      }
      return true;
    }).toList();

    final mappedItems = filteredListings
        .where((item) => _coordinatesOf(item) != null)
        .toList();

    final selected = _selectedProperty ??
        (filteredListings.isNotEmpty ? filteredListings.first : null);
    final initialCenter =
        (selected != null ? _coordinatesOf(selected) : null) ??
            (mappedItems.isNotEmpty
                ? _coordinatesOf(mappedItems.first)!
                : _defaultEgyptCenter);

    final subtitle = selected != null
        ? selected.localizedLocation(isArabic ? 'ar' : 'en')
        : (isArabic ? 'خريطة العقارات المتاحة' : 'Available Properties Map');

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: Stack(
        children: [
          // 1. Interactive FlutterMap Layer
          if (homeState.isInitialLoading && allListings.isEmpty)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (homeState.error != null && allListings.isEmpty)
            DealOneErrorStateView(
              error: homeState.error!,
              onRetry: () => ref
                  .read(
                    sectionHomeControllerProvider(
                      RealEstateHomePage.sectionSlug,
                    ).notifier,
                  )
                  .loadInitial(forceRefresh: true),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: _currentZoom,
                onTap: (_, _) {
                  if (_selectedProperty != null) {
                    setState(() => _selectedProperty = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _useAlternateTileStyle
                      ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.dealone.marketspace',
                ),
                MarkerLayer(
                  markers: mappedItems.map((item) {
                    final point = _coordinatesOf(item)!;
                    final isSelected = selected?.id == item.id;
                    return Marker(
                      point: point,
                      width: isSelected ? 185 : 54,
                      height: isSelected ? 98 : 54,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedProperty = item);
                          _mapController.move(point, _currentZoom);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: DealOneTokens.navy,
                                  borderRadius: AppRadii.full,
                                  boxShadow: DealOneTokens.cardShadow(context),
                                ),
                                child: Text(
                                  formatDealOnePrice(
                                    item.price,
                                    currency: item.currency,
                                    isArabic: isArabic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: DealOneTokens.amberWarm,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            Container(
                              width: isSelected ? 46 : 38,
                              height: isSelected ? 46 : 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DealOneTokens.navy
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? DealOneTokens.amber
                                      : DealOneTokens.navy,
                                  width: 2.5,
                                ),
                                boxShadow: DealOneTokens.cardShadow(context),
                              ),
                              child: Icon(
                                Icons.apartment_rounded,
                                size: isSelected ? 22 : 18,
                                color: isSelected
                                    ? Colors.white
                                    : DealOneTokens.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          // 2. Floating Top Header Card + Filter Chips
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: DealOneTokens.cardDecoration(
                      context,
                      borderRadius: AppRadii.xl,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (context.canPop()) context.pop();
                          },
                          borderRadius: AppRadii.md,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: DealOneTokens.softTileBgOf(context),
                              borderRadius: AppRadii.md,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isArabic
                                    ? 'الموقع الجغرافي'
                                    : 'Geographic Location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: DealOneTokens.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: DealOneTokens.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: DealOneTokens.textSecondaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        InkWell(
                          onTap: () => setState(
                            () => _useAlternateTileStyle =
                                !_useAlternateTileStyle,
                          ),
                          borderRadius: AppRadii.md,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DealOneTokens.softTileBgOf(context),
                              borderRadius: AppRadii.md,
                            ),
                            child: Icon(
                              Icons.layers_outlined,
                              size: 19,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MapFilterChip(
                          label: isArabic ? 'الكل' : 'All',
                          icon: Icons.apps_rounded,
                          selected: _activeFilter == 'all',
                          onTap: () => setState(() => _activeFilter = 'all'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MapFilterChip(
                          label: isArabic ? 'للإيجار' : 'For Rent',
                          icon: Icons.key_outlined,
                          selected: _activeFilter == 'rent',
                          onTap: () => setState(() => _activeFilter = 'rent'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MapFilterChip(
                          label: isArabic ? 'للبيع' : 'For Sale',
                          icon: Icons.home_outlined,
                          selected: _activeFilter == 'sale',
                          onTap: () => setState(() => _activeFilter = 'sale'),
                        ),
                      ],
                    ),
                  ),

                  // Coordinates / Permission Info Banner (Honest backend state)
                  if (mappedItems.isEmpty && !homeState.isInitialLoading) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
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
                                  ? 'إحداثيات GPS الدقيقة غير مرفقة في استجابة القائمة الحالية؛ يتم عرض المنطقة الجغرافية للعقار.'
                                  : 'Exact GPS pins are not yet serialized in the listings payload; showing property area context.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: DealOneTokens.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_locationPermissionDenied) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: DealOneTokens.dangerSoftBg,
                        borderRadius: AppRadii.md,
                      ),
                      child: Text(
                        isArabic
                            ? 'صلاحية الموقع غير مفعلة — يمكنك تصفح الخريطة يدوياً.'
                            : 'Location permission denied — you can still pan and explore manually.',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: DealOneTokens.dangerRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls
          PositionedDirectional(
            end: hPad,
            top: MediaQuery.sizeOf(context).height * 0.28,
            child: MapFloatingControls(
              onMyLocationTap: _handleLocationPermissionTap,
              onRecenterTap: () => _mapController.move(initialCenter, 13.5),
              onZoomIn: () => _zoomBy(1.0),
              onZoomOut: () => _zoomBy(-1.0),
            ),
          ),

          // 4. Animated Bottom Property Preview Sheet
          if (selected != null)
            Positioned(
              left: hPad,
              right: hPad,
              bottom: AppSpacing.md,
              child: SafeArea(
                top: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                    ),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: MapPropertyPreviewCard(
                    key: ValueKey(selected.id),
                    property: selected,
                    onOpenDetails: () =>
                        context.push('/listings/${selected.id}'),
                    onContactSeller: () => _startChatWithSeller(selected),
                    onClose: () => setState(() => _selectedProperty = null),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DealOneTokens.navy
          : DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: selected
                  ? DealOneTokens.navy
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : DealOneTokens.textPrimaryOf(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
