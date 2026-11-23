import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/home/providers/category_business_overview_provider.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Compact, strictly capability-gated "My Business Overview" section rendered
/// inside each of the 6 Category Home Pages ONLY when the authenticated user
/// holds verified backend capabilities for [categorySlug].
///
/// - Buyers & guests: renders [SizedBox.shrink] with zero flicker and zero API calls.
/// - Activated sellers/providers: renders compact stats + quick actions linked
///   directly to existing management and creation routes.
/// - Cars & Maintenance: strictly separates Car Sales widgets from Maintenance
///   Provider widgets; Multi-Capability accounts see both independently.
class RoleBasedBusinessSection extends ConsumerWidget {
  final String categorySlug;

  const RoleBasedBusinessSection({
    super.key,
    required this.categorySlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
    final overview = ref.watch(categoryBusinessOverviewProvider(normalized));
    if (overview == null) {
      return const SizedBox.shrink();
    }

    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;

    return Padding(
      key: Key('role_based_business_section_$normalized'),
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 6),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: normalized == MapCategoryRegistry.carsSlug
            ? _buildAutomotiveBlocks(context, ref, overview, isArabic)
            : _BusinessOverviewCard(
                cardKey: Key('business_overview_card_$normalized'),
                title: _titleForSection(normalized, isArabic),
                subtitle: overview.accountName,
                isLoading: overview.isLoading,
                error: overview.error,
                onRetry: () => ref
                    .read(sellerListingsControllerProvider(normalized).notifier)
                    .loadInitial(),
                stats: _statsForSection(context, normalized, overview, isArabic),
                primaryActionLabel: _createLabelForSection(normalized, isArabic),
                primaryActionIcon: Icons.add_circle_outline_rounded,
                primaryActionKey: Key('business_quick_create_$normalized'),
                onPrimaryAction: () => context.push(
                  RouteNames.createListingFor(
                    normalized,
                    listingKind: _listingKindForSection(normalized),
                  ),
                ),
                secondaryActionLabel:
                    _manageLabelForSection(normalized, isArabic),
                secondaryActionKey: Key('business_quick_manage_$normalized'),
                onSecondaryAction: () => context.push(
                  RouteNames.sellerManagementFor(
                    normalized,
                    _managementModeForSection(normalized),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAutomotiveBlocks(
    BuildContext context,
    WidgetRef ref,
    CategoryBusinessOverview overview,
    bool isArabic,
  ) {
    final blocks = <Widget>[];

    if (overview.showAutomotiveSales) {
      blocks.add(
        _BusinessOverviewCard(
          cardKey: const Key('business_overview_card_cars_sales'),
          title: isArabic ? 'إدارة نشاط السيارات' : 'Automotive Sales Overview',
          subtitle: overview.accountName,
          isLoading: overview.isLoading,
          error: overview.error,
          onRetry: () => ref
              .read(
                sellerListingsControllerProvider(MapCategoryRegistry.carsSlug)
                    .notifier,
              )
              .loadInitial(),
          stats: [
            _StatTileData(
              key: const Key('stat_cars_total'),
              label: isArabic ? 'سياراتي' : 'My Cars',
              value: '${overview.totalListings}',
              icon: Icons.directions_car_outlined,
              onTap: () => context.push(
                RouteNames.sellerManagementFor(
                  MapCategoryRegistry.carsSlug,
                  'listings',
                ),
              ),
            ),
            _StatTileData(
              key: const Key('stat_cars_pending'),
              label: isArabic ? 'قيد المراجعة' : 'Pending',
              value: '${overview.pendingModerationListings}',
              icon: Icons.hourglass_top_rounded,
              onTap: () => context.push(
                RouteNames.sellerManagementFor(
                  MapCategoryRegistry.carsSlug,
                  'listings',
                ),
              ),
            ),
            if (overview.incomingInquiriesCount != null)
              _StatTileData(
                key: const Key('stat_cars_inquiries'),
                label: isArabic ? 'الاستفسارات' : 'Inquiries',
                value: '${overview.incomingInquiriesCount}',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => context.push(RouteNames.conversations),
              ),
            if (overview.totalViews != null)
              _StatTileData(
                key: const Key('stat_cars_views'),
                label: isArabic ? 'المشاهدات' : 'Views',
                value: '${overview.totalViews}',
                icon: Icons.visibility_outlined,
              ),
          ],
          primaryActionLabel: isArabic ? 'أضف سيارة' : 'Add Car',
          primaryActionIcon: Icons.add_circle_outline_rounded,
          primaryActionKey: const Key('business_quick_create_cars_sales'),
          onPrimaryAction: () => context.push(
            RouteNames.createListingFor(
              MapCategoryRegistry.carsSlug,
              listingKind: 'sale',
            ),
          ),
          secondaryActionLabel: isArabic ? 'إدارة السيارات' : 'Manage Cars',
          secondaryActionKey: const Key('business_quick_manage_cars_sales'),
          onSecondaryAction: () => context.push(
            RouteNames.sellerManagementFor(
              MapCategoryRegistry.carsSlug,
              'listings',
            ),
          ),
        ),
      );
    }

    if (overview.showAutomotiveMaintenance) {
      if (blocks.isNotEmpty) {
        blocks.add(const SizedBox(height: 10));
      }
      blocks.add(
        _BusinessOverviewCard(
          cardKey: const Key('business_overview_card_cars_maintenance'),
          title: isArabic
              ? 'إدارة خدمات الصيانة'
              : 'Maintenance Provider Overview',
          subtitle: overview.accountName,
          isLoading: overview.isLoading,
          error: overview.error,
          onRetry: () => ref.invalidate(
            providerIncomingBookingsProvider(MapCategoryRegistry.carsSlug),
          ),
          stats: [
            _StatTileData(
              key: const Key('stat_maint_services'),
              label: isArabic ? 'خدمات الصيانة' : 'My Services',
              value: '${overview.totalListings}',
              icon: Icons.build_circle_outlined,
              onTap: () => context.push(
                RouteNames.sellerManagementFor(
                  MapCategoryRegistry.carsSlug,
                  'services',
                ),
              ),
            ),
            _StatTileData(
              key: const Key('stat_maint_requests'),
              label: isArabic ? 'طلبات الصيانة' : 'Requests',
              value: '${overview.incomingBookingsCount}',
              icon: Icons.inbox_outlined,
              onTap: () => context.push(
                '${RouteNames.sellerManagementFor(MapCategoryRegistry.carsSlug, 'services')}?tab=incoming',
              ),
            ),
            _StatTileData(
              key: const Key('stat_maint_upcoming'),
              label: isArabic ? 'مواعيد قادمة' : 'Upcoming',
              value: '${overview.upcomingAppointmentsCount}',
              icon: Icons.event_available_outlined,
              onTap: () => context.push(
                '${RouteNames.sellerManagementFor(MapCategoryRegistry.carsSlug, 'services')}?tab=incoming',
              ),
            ),
          ],
          primaryActionLabel:
              isArabic ? 'أضف خدمة صيانة' : 'Add Maintenance Service',
          primaryActionIcon: Icons.add_circle_outline_rounded,
          primaryActionKey: const Key('business_quick_create_cars_maintenance'),
          onPrimaryAction: () => context.push(
            RouteNames.createListingFor(
              MapCategoryRegistry.carsSlug,
              listingKind: 'service',
            ),
          ),
          secondaryActionLabel: isArabic ? 'إدارة الصيانة' : 'Manage Services',
          secondaryActionKey:
              const Key('business_quick_manage_cars_maintenance'),
          onSecondaryAction: () => context.push(
            RouteNames.sellerManagementFor(
              MapCategoryRegistry.carsSlug,
              'services',
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  List<_StatTileData> _statsForSection(
    BuildContext context,
    String slug,
    CategoryBusinessOverview overview,
    bool isArabic,
  ) {
    final manageRoute = RouteNames.sellerManagementFor(
      slug,
      _managementModeForSection(slug),
    );

    switch (slug) {
      case MapCategoryRegistry.servicesSlug:
        return [
          _StatTileData(
            key: const Key('stat_services_total'),
            label: isArabic ? 'خدماتي' : 'My Services',
            value: '${overview.totalListings}',
            icon: Icons.engineering_outlined,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: const Key('stat_services_pending'),
            label: isArabic ? 'قيد المراجعة' : 'Pending',
            value: '${overview.pendingModerationListings}',
            icon: Icons.hourglass_top_rounded,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: const Key('stat_services_bookings'),
            label: isArabic ? 'حجوزات واردة' : 'Incoming',
            value: '${overview.incomingBookingsCount}',
            icon: Icons.calendar_today_outlined,
            onTap: () => context.push('$manageRoute?tab=incoming'),
          ),
          _StatTileData(
            key: const Key('stat_services_upcoming'),
            label: isArabic ? 'مواعيد قادمة' : 'Upcoming',
            value: '${overview.upcomingAppointmentsCount}',
            icon: Icons.event_available_outlined,
            onTap: () => context.push('$manageRoute?tab=incoming'),
          ),
        ];

      case MapCategoryRegistry.buildingMaterialsSlug:
        return [
          _StatTileData(
            key: const Key('stat_materials_total'),
            label: isArabic ? 'منتجاتي' : 'My Products',
            value: '${overview.totalListings}',
            icon: Icons.inventory_2_outlined,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: const Key('stat_materials_pending'),
            label: isArabic ? 'قيد المراجعة' : 'Pending',
            value: '${overview.pendingModerationListings}',
            icon: Icons.hourglass_top_rounded,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: const Key('stat_materials_rfqs'),
            label: isArabic ? 'طلبات أسعار واردة' : 'Incoming RFQs',
            value: '${overview.incomingRfqsCount}',
            icon: Icons.request_quote_outlined,
            onTap: () => context.push('$manageRoute?tab=incoming'),
          ),
          _StatTileData(
            key: const Key('stat_materials_quotes'),
            label: isArabic ? 'عروضي المقدمة' : 'Quotations',
            value: '${overview.submittedQuotationsCount}',
            icon: Icons.description_outlined,
            onTap: () => context.push('$manageRoute?tab=incoming'),
          ),
        ];

      default:
        // Real Estate, Appliances & Decor, Fashion & Accessories
        return [
          _StatTileData(
            key: Key('stat_${slug}_total'),
            label: isArabic ? 'إعلاناتي' : 'My Listings',
            value: '${overview.totalListings}',
            icon: Icons.list_alt_rounded,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: Key('stat_${slug}_published'),
            label: isArabic ? 'منشورة' : 'Published',
            value: '${overview.publishedListings}',
            icon: Icons.check_circle_outline_rounded,
            onTap: () => context.push(manageRoute),
          ),
          _StatTileData(
            key: Key('stat_${slug}_pending'),
            label: isArabic ? 'قيد المراجعة' : 'Pending',
            value: '${overview.pendingModerationListings}',
            icon: Icons.hourglass_top_rounded,
            onTap: () => context.push(manageRoute),
          ),
          if (overview.incomingInquiriesCount != null)
            _StatTileData(
              key: Key('stat_${slug}_inquiries'),
              label: isArabic ? 'الاستفسارات' : 'Inquiries',
              value: '${overview.incomingInquiriesCount}',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => context.push(RouteNames.conversations),
            ),
          if (overview.totalViews != null)
            _StatTileData(
              key: Key('stat_${slug}_views'),
              label: isArabic ? 'المشاهدات' : 'Views',
              value: '${overview.totalViews}',
              icon: Icons.visibility_outlined,
            ),
        ];
    }
  }

  String _titleForSection(String slug, bool isArabic) {
    switch (slug) {
      case MapCategoryRegistry.realEstateSlug:
        return isArabic ? 'إدارة نشاطي العقاري' : 'Real Estate Business Overview';
      case MapCategoryRegistry.servicesSlug:
        return isArabic ? 'إدارة خدماتي الهندسية' : 'Service Provider Overview';
      case MapCategoryRegistry.buildingMaterialsSlug:
        return isArabic ? 'إدارة التوريدات والمواد' : 'Supplier Business Overview';
      case MapCategoryRegistry.homeAppliancesSlug:
        return isArabic
            ? 'إدارة إعلانات الأجهزة والديكور'
            : 'Appliances Seller Overview';
      case MapCategoryRegistry.fashionSlug:
        return isArabic ? 'إدارة متجر الأزياء' : 'Fashion Seller Overview';
      default:
        return isArabic ? 'ملخص نشاطي' : 'My Business Overview';
    }
  }

  String _createLabelForSection(String slug, bool isArabic) {
    switch (slug) {
      case MapCategoryRegistry.realEstateSlug:
        return isArabic ? 'أضف عقارك' : 'Add Property';
      case MapCategoryRegistry.servicesSlug:
        return isArabic ? 'أضف خدمة' : 'Add Service';
      case MapCategoryRegistry.buildingMaterialsSlug:
        return isArabic ? 'أضف منتج' : 'Add Product';
      default:
        return isArabic ? 'أضف إعلانك' : 'Add Listing';
    }
  }

  String _manageLabelForSection(String slug, bool isArabic) {
    switch (slug) {
      case MapCategoryRegistry.servicesSlug:
        return isArabic ? 'إدارة الخدمات' : 'Manage Services';
      case MapCategoryRegistry.buildingMaterialsSlug:
        return isArabic ? 'إدارة المنتجات' : 'Manage Products';
      default:
        return isArabic ? 'إدارة الإعلانات' : 'Manage Listings';
    }
  }

  String _managementModeForSection(String slug) {
    switch (slug) {
      case MapCategoryRegistry.servicesSlug:
        return 'services';
      case MapCategoryRegistry.buildingMaterialsSlug:
        return 'products';
      default:
        return 'listings';
    }
  }

  String _listingKindForSection(String slug) {
    switch (slug) {
      case MapCategoryRegistry.servicesSlug:
        return 'service';
      case MapCategoryRegistry.buildingMaterialsSlug:
      case MapCategoryRegistry.homeAppliancesSlug:
      case MapCategoryRegistry.fashionSlug:
        return 'product';
      default:
        return 'sale';
    }
  }
}

class _StatTileData {
  final Key? key;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatTileData({
    this.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
}

class _BusinessOverviewCard extends StatelessWidget {
  final Key cardKey;
  final String title;
  final String subtitle;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final List<_StatTileData> stats;
  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final Key primaryActionKey;
  final VoidCallback onPrimaryAction;
  final String secondaryActionLabel;
  final Key secondaryActionKey;
  final VoidCallback onSecondaryAction;

  const _BusinessOverviewCard({
    required this.cardKey,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.stats,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.primaryActionKey,
    required this.onPrimaryAction,
    required this.secondaryActionLabel,
    required this.secondaryActionKey,
    required this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : DealOneDesignColors.navy.withValues(alpha: 0.12),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: DealOneDesignColors.navy.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DealOneDesignColors.navy.withValues(
                    alpha: isDark ? 0.45 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  size: 18,
                  color: isDark ? Colors.white : DealOneDesignColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : DealOneDesignColors.navy,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تعذر تحديث ملخص النشاط حالياً'
                        : 'Could not refresh business summary',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: Text(isArabic ? 'إعادة' : 'Retry'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 460 ? 4 : 2;
                final tileWidth =
                    (constraints.maxWidth - ((columns - 1) * 8)) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats
                      .map(
                        (s) => SizedBox(
                          width: tileWidth,
                          child: _CompactStatTile(data: s),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: primaryActionKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DealOneDesignColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onPrimaryAction,
                  icon: Icon(primaryActionIcon, size: 17),
                  label: Text(
                    primaryActionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: secondaryActionKey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : DealOneDesignColors.navy,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : DealOneDesignColors.navy.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onSecondaryAction,
                  child: Text(
                    secondaryActionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  final _StatTileData data;

  const _CompactStatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      key: data.key,
      color: DealOneTokens.softTileBgOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                data.icon,
                size: 16,
                color: isDark ? Colors.white70 : DealOneDesignColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.value,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.white
                            : DealOneDesignColors.navy,
                      ),
                    ),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
