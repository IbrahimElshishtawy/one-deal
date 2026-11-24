import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_section_bottom_nav.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/data/repositories/bookings_repository_impl.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Unified Seller / Provider Management screen supporting:
/// - `listings`: My Listings (Real Estate, Appliances & Decor, Fashion)
/// - `services`: My Services + Incoming Requests tab (Services & Engineering, Cars Maintenance)
/// - `products`: My Products + Incoming RFQs tab (Building Materials & Electricity)
///
/// Strictly enforces backend-verified seller capability before rendering
/// management actions or creation controls.
class SellerManagementPage extends ConsumerStatefulWidget {
  final String categorySlug;
  final String mode; // 'listings' | 'services' | 'products'
  final int initialTabIndex;

  const SellerManagementPage({
    super.key,
    required this.categorySlug,
    required this.mode,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SellerManagementPage> createState() =>
      _SellerManagementPageState();
}

class _SellerManagementPageState extends ConsumerState<SellerManagementPage>
    with SingleTickerProviderStateMixin {
  late final String _slug;
  TabController? _tabController;
  final ScrollController _scrollController = ScrollController();

  bool get _hasSecondaryTab =>
      widget.mode == 'services' || widget.mode == 'products';

  String get _activeNavTabId {
    switch (widget.mode) {
      case 'services':
        return SectionNavigationRegistry.myServicesTabId;
      case 'products':
        return SectionNavigationRegistry.myProductsTabId;
      default:
        return SectionNavigationRegistry.myListingsTabId;
    }
  }

  @override
  void initState() {
    super.initState();
    _slug = MapCategoryRegistry.normalizeSlug(widget.categorySlug);
    if (_hasSecondaryTab) {
      _tabController = TabController(
        length: 2,
        initialIndex: widget.initialTabIndex.clamp(0, 1),
        vsync: this,
      );
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 280) {
      ref.read(sellerListingsControllerProvider(_slug).notifier).loadMore();
    }
  }

  String _pageTitle(bool isArabic) {
    switch (widget.mode) {
      case 'services':
        return _slug == MapCategoryRegistry.carsSlug
            ? (isArabic ? 'خدمات الصيانة' : 'My Maintenance Services')
            : (isArabic ? 'خدماتي' : 'My Services');
      case 'products':
        return isArabic ? 'منتجاتي وإعلانات المواد' : 'My Products';
      default:
        return isArabic ? 'إعلاناتي' : 'My Listings';
    }
  }

  String _createButtonLabel(bool isArabic) {
    switch (widget.mode) {
      case 'services':
        return isArabic ? 'إضافة خدمة' : 'Create Service';
      case 'products':
        return isArabic ? 'إضافة منتج' : 'Add Product';
      default:
        return isArabic ? 'إضافة إعلان' : 'Create Listing';
    }
  }

  String _listingKindForCreate() {
    switch (widget.mode) {
      case 'services':
        return 'service';
      case 'products':
        return 'product';
      default:
        return 'sale';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final capabilities = ref.watch(accountCapabilitiesProvider);
    final isAuthorized = capabilities.isActivatedSellerForSection(_slug);

    if (capabilities.isLoading) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        bottomNavigationBar: DealOneSectionBottomNav(
          sectionId: _slug,
          activeTabId: _activeNavTabId,
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        bottomNavigationBar: DealOneSectionBottomNav(
          sectionId: _slug,
          activeTabId: SectionNavigationRegistry.favoritesTabId,
        ),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: _pageTitle(isArabic),
                showBackButton: Navigator.of(context).canPop(),
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.verified_user_outlined,
                  title: isArabic
                      ? 'يتطلب حساب بائع مفعّل لهذا القسم'
                      : 'Activated Seller Account Required',
                  description: isArabic
                      ? 'إدارة الإعلانات والخدمات متاحة فقط بعد تفعيل وتوثيق حسابك التجاري من الخادم لهذا النشاط.'
                      : 'Managing listings or services requires a backend-verified and activated account for this sector.',
                  actionLabel: isArabic ? 'إدارة الحساب' : 'Go to Profile',
                  actionIcon: Icons.person_outline_rounded,
                  onAction: () => context.go(RouteNames.profile),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      extendBody: true,
      bottomNavigationBar: DealOneSectionBottomNav(
        sectionId: _slug,
        activeTabId: _activeNavTabId,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton.extended(
          key: Key('seller_create_btn_${widget.mode}'),
          backgroundColor: DealOneTokens.navy,
          foregroundColor: Colors.white,
          onPressed: () => context.push(
            RouteNames.createListingFor(
              _slug,
              listingKind: _listingKindForCreate(),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(_createButtonLabel(isArabic)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: _pageTitle(isArabic),
              showBackButton: Navigator.of(context).canPop(),
            ),
            if (_hasSecondaryTab && _tabController != null)
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: context.horizontalScreenPadding,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DealOneTokens.cardSurfaceOf(context),
                  borderRadius: AppRadii.md,
                  border: Border.all(color: DealOneTokens.cardBorderOf(context)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: DealOneTokens.navy,
                  unselectedLabelColor: DealOneTokens.textSecondaryOf(context),
                  tabs: [
                    Tab(
                      text: widget.mode == 'services'
                          ? (isArabic ? 'خدماتي' : 'My Services')
                          : (isArabic ? 'منتجاتي' : 'My Products'),
                    ),
                    Tab(
                      text: widget.mode == 'services'
                          ? (isArabic ? 'الطلبات الواردة' : 'Incoming Requests')
                          : (isArabic ? 'طلبات الأسعار الواردة' : 'Incoming RFQs'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _hasSecondaryTab && _tabController != null
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _OwnListingsListView(
                          slug: _slug,
                          mode: widget.mode,
                          scrollController: _scrollController,
                        ),
                        if (widget.mode == 'services')
                          _IncomingProviderBookingsTab(slug: _slug)
                        else
                          _IncomingSupplierRfqsTab(slug: _slug),
                      ],
                    )
                  : _OwnListingsListView(
                      slug: _slug,
                      mode: widget.mode,
                      scrollController: _scrollController,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnListingsListView extends ConsumerWidget {
  final String slug;
  final String mode;
  final ScrollController scrollController;

  const _OwnListingsListView({
    required this.slug,
    required this.mode,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final state = ref.watch(sellerListingsControllerProvider(slug));
    final notifier = ref.read(sellerListingsControllerProvider(slug).notifier);
    final items = state.filteredItems;

    return RefreshIndicator(
      color: DealOneTokens.navy,
      onRefresh: notifier.loadInitial,
      child: ListView(
        key: PageStorageKey<String>('seller_listings_scroll_${slug}_$mode'),
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 150),
        children: [
          if (state.ownerEndpointGapActive)
            _BackendGapNoticeBanner(isArabic: isArabic),
          const SizedBox(height: AppSpacing.sm),
          _OrthogonalAxisFiltersRow(
            state: state,
            isArabic: isArabic,
            onModerationSelected: notifier.setModerationFilter,
            onPublicationSelected: notifier.setPublicationFilter,
            onAvailabilitySelected: notifier.setAvailabilityFilter,
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.isLoading && state.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator.adaptive()),
            )
          else if (state.error != null && state.items.isEmpty)
            DealOneErrorStateView(
              error: state.error!,
              onRetry: notifier.loadInitial,
            )
          else if (items.isEmpty)
            DealOneEmptyStateView(
              icon: mode == 'services'
                  ? Icons.engineering_outlined
                  : mode == 'products'
                      ? Icons.inventory_2_outlined
                      : Icons.list_alt_outlined,
              title: mode == 'services'
                  ? (isArabic ? 'لا توجد خدمات منشورة بعد' : 'No published services yet')
                  : mode == 'products'
                      ? (isArabic ? 'لا توجد منتجات منشورة بعد' : 'No published products yet')
                      : (isArabic ? 'لا توجد إعلانات منشورة بعد' : 'No published listings yet'),
              description: isArabic
                  ? 'اضغط على زر الإضافة بالأسفل لإنشاء عنصر جديد وإرساله للمراجعة والنشر.'
                  : 'Tap the create button below to add a new item for review and publication.',
            )
          else ...[
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SellerListingCard(
                  item: item,
                  isArabic: isArabic,
                  isMutating: state.isMutating,
                  onToggleHide: () {
                    final nextStatus =
                        item.publicationStatus.toLowerCase() == 'hidden'
                            ? 'published'
                            : 'hidden';
                    notifier.updatePublicationStatus(item.id, nextStatus);
                  },
                  onChangeAvailability: (avail) =>
                      notifier.updateAvailability(item.id, avail),
                  onDelete: () => notifier.deleteListing(item.id),
                  onOpenDetail: () => context.push('/listings/${item.id}'),
                ),
              ),
            ),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
          ],
        ],
      ),
    );
  }
}

class _BackendGapNoticeBanner extends StatelessWidget {
  final bool isArabic;

  const _BackendGapNoticeBanner({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('seller_owner_endpoint_gap_banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: AppRadii.md,
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic
                  ? 'يتم عرض إعلانات حسابك المنشورة حالياً. عرض المسودات وقيد المراجعة والمرفوضة والمخفية يتطلب تفعيل مسار GET /api/v1/listings/my في الخادم.'
                  : 'Showing your account’s published items. Listing Draft, Pending, Rejected, Hidden, and Archived records requires adding GET /api/v1/listings/my on the backend.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrthogonalAxisFiltersRow extends StatelessWidget {
  final SellerListingsState state;
  final bool isArabic;
  final ValueChanged<String?> onModerationSelected;
  final ValueChanged<String?> onPublicationSelected;
  final ValueChanged<String?> onAvailabilitySelected;

  const _OrthogonalAxisFiltersRow({
    required this.state,
    required this.isArabic,
    required this.onModerationSelected,
    required this.onPublicationSelected,
    required this.onAvailabilitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _AxisFilterChip(
            label: isArabic
                ? 'المراجعة: ${state.selectedModerationFilter ?? 'الكل'}'
                : 'Moderation: ${state.selectedModerationFilter ?? 'All'}',
            options: const ['draft', 'pending', 'approved', 'rejected'],
            selected: state.selectedModerationFilter,
            onSelected: onModerationSelected,
          ),
          const SizedBox(width: 8),
          _AxisFilterChip(
            label: isArabic
                ? 'النشر: ${state.selectedPublicationFilter ?? 'الكل'}'
                : 'Publication: ${state.selectedPublicationFilter ?? 'All'}',
            options: const ['published', 'hidden', 'expired', 'archived'],
            selected: state.selectedPublicationFilter,
            onSelected: onPublicationSelected,
          ),
          const SizedBox(width: 8),
          _AxisFilterChip(
            label: isArabic
                ? 'التوافر: ${state.selectedAvailabilityFilter ?? 'الكل'}'
                : 'Availability: ${state.selectedAvailabilityFilter ?? 'All'}',
            options: const ['available', 'reserved', 'sold', 'rented'],
            selected: state.selectedAvailabilityFilter,
            onSelected: onAvailabilitySelected,
          ),
        ],
      ),
    );
  }
}

class _AxisFilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _AxisFilterChip({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => onSelected(value == '__all__' ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(value: '__all__', child: Text('All / الكل')),
        ...options.map(
          (o) => PopupMenuItem<String>(value: o, child: Text(o)),
        ),
      ],
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        avatar: Icon(
          selected == null ? Icons.filter_list_rounded : Icons.check_circle,
          size: 16,
        ),
      ),
    );
  }
}

class _SellerListingCard extends StatelessWidget {
  final ListingItem item;
  final bool isArabic;
  final bool isMutating;
  final VoidCallback onToggleHide;
  final ValueChanged<String> onChangeAvailability;
  final VoidCallback onDelete;
  final VoidCallback onOpenDetail;

  const _SellerListingCard({
    required this.item,
    required this.isArabic,
    required this.isMutating,
    required this.onToggleHide,
    required this.onChangeAvailability,
    required this.onDelete,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final isHidden = item.publicationStatus.toLowerCase() == 'hidden';

    return Material(
      color: DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: AppRadii.lg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.lg,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.price.toStringAsFixed(0)} ${item.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: DealOneTokens.navy,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 3 Independent Orthogonal Axes — never conflated.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusPill(
                    prefix: isArabic ? 'المراجعة' : 'Moderation',
                    value: item.moderationStatus,
                    color: const Color(0xFF1D4ED8),
                  ),
                  _StatusPill(
                    prefix: isArabic ? 'النشر' : 'Publication',
                    value: item.publicationStatus,
                    color: const Color(0xFF047857),
                  ),
                  _StatusPill(
                    prefix: isArabic ? 'التوافر' : 'Availability',
                    value: item.availabilityStatus,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: isMutating ? null : onToggleHide,
                    icon: Icon(
                      isHidden
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_outlined,
                      size: 16,
                    ),
                    label: Text(
                      isHidden
                          ? (isArabic ? 'إعادة نشر' : 'Republish')
                          : (isArabic ? 'إخفاء' : 'Hide'),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !isMutating,
                    onSelected: onChangeAvailability,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'available', child: Text('Available / متاح')),
                      PopupMenuItem(value: 'reserved', child: Text('Reserved / محجوز')),
                      PopupMenuItem(value: 'sold', child: Text('Sold / مباع')),
                      PopupMenuItem(value: 'rented', child: Text('Rented / مؤجر')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'التوافر' : 'Availability',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: isArabic ? 'حذف' : 'Delete',
                    onPressed: isMutating ? null : onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String prefix;
  final String value;
  final Color color;

  const _StatusPill({
    required this.prefix,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$prefix: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _IncomingProviderBookingsTab extends ConsumerWidget {
  final String slug;

  const _IncomingProviderBookingsTab({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final asyncBookings = ref.watch(providerIncomingBookingsProvider(slug));

    return asyncBookings.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => DealOneErrorStateView(
        error: err,
        onRetry: () => ref.invalidate(providerIncomingBookingsProvider(slug)),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return DealOneEmptyStateView(
            icon: Icons.inbox_outlined,
            title: isArabic
                ? 'لا توجد طلبات حجز واردة حالياً'
                : 'No incoming booking requests',
            description: isArabic
                ? 'عندما يقوم العملاء بحجز خدماتك ستظهر الطلبات هنا للموافقة أو الرفض.'
                : 'Incoming customer booking requests for your services will appear here.',
          );
        }
        return RefreshIndicator(
          color: DealOneTokens.navy,
          onRefresh: () async =>
              ref.invalidate(providerIncomingBookingsProvider(slug)),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 140),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = bookings[index];
              return _IncomingBookingCard(
                booking: b,
                isArabic: isArabic,
                onUpdateStatus: (nextStatus) async {
                  final repo = ref.read(bookingsRepositoryProvider);
                  if (repo is BookingsRepositoryImpl) {
                    await repo.updateBookingStatus(b.id, nextStatus);
                    ref.invalidate(providerIncomingBookingsProvider(slug));
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _IncomingBookingCard extends StatelessWidget {
  final BookingEntity booking;
  final bool isArabic;
  final Future<void> Function(String status) onUpdateStatus;

  const _IncomingBookingCard({
    required this.booking,
    required this.isArabic,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == BookingStatus.pending;
    final isConfirmed = booking.status == BookingStatus.confirmed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: DealOneTokens.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                booking.rawStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DealOneTokens.navy,
                ),
              ),
            ],
          ),
          if (booking.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.address,
              style: TextStyle(
                fontSize: 12.5,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
          ],
          if (isPending || isConfirmed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isPending) ...[
                  ElevatedButton(
                    onPressed: () => onUpdateStatus('CONFIRMED'),
                    child: Text(isArabic ? 'تأكيد' : 'Confirm'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => onUpdateStatus('REJECTED'),
                    child: Text(isArabic ? 'رفض' : 'Reject'),
                  ),
                ],
                if (isConfirmed)
                  ElevatedButton(
                    onPressed: () => onUpdateStatus('COMPLETED'),
                    child: Text(isArabic ? 'إتمام' : 'Complete'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IncomingSupplierRfqsTab extends ConsumerWidget {
  final String slug;

  const _IncomingSupplierRfqsTab({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final asyncRfqs = ref.watch(supplierOpenRfqsProvider(slug));

    return asyncRfqs.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (err, _) => DealOneErrorStateView(
        error: err,
        onRetry: () => ref.invalidate(supplierOpenRfqsProvider(slug)),
      ),
      data: (rfqs) {
        if (rfqs.isEmpty) {
          return DealOneEmptyStateView(
            icon: Icons.request_quote_outlined,
            title: isArabic
                ? 'لا توجد طلبات أسعار واردة حالياً'
                : 'No open buyer RFQs',
            description: isArabic
                ? 'ستظهر هنا طلبات التسعير المفتوحة من المشترين لتقديم عرض السعر الخاص بك كمورد.'
                : 'Open buyer price requests eligible for supplier quotations will appear here.',
          );
        }
        return RefreshIndicator(
          color: DealOneTokens.navy,
          onRefresh: () async => ref.invalidate(supplierOpenRfqsProvider(slug)),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 140),
            itemCount: rfqs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _SupplierRfqCard(
              rfq: rfqs[index],
              isArabic: isArabic,
            ),
          ),
        );
      },
    );
  }
}

class _SupplierRfqCard extends StatelessWidget {
  final RfqRequestEntity rfq;
  final bool isArabic;

  const _SupplierRfqCard({required this.rfq, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: DealOneTokens.cardBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rfq.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Text(
                rfq.referenceNumber,
                style: TextStyle(
                  fontSize: 11.5,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rfq.materialsSummary,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${isArabic ? 'الكمية:' : 'Qty:'} ${rfq.quantitySummary} • ${rfq.deliveryLocation}',
            style: TextStyle(
              fontSize: 12,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
