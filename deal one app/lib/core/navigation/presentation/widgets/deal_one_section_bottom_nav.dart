import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_tokens.dart';
import 'package:market_space/core/navigation/config/navigation_item_config.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/presentation/widgets/active_navigation_indicator.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

/// Unified, Role-Aware Bottom Navigation bar for Deal One's 6 category sections.
///
/// - Dynamically resolves items from [sectionNavigationConfigProvider] based on
///   active category context + verified Backend [AccountCapabilities].
/// - Prevents Favorites -> Seller Action flicker during initial account load
///   by rendering a calm loading placeholder in the role-sensitive slot.
/// - Displays unread chat count & cart count badges when available.
/// - Preserves RTL/LTR alignment, clamped text scaling, SafeArea, and keyboard auto-hide.
class DealOneSectionBottomNav extends ConsumerWidget {
  final String sectionId;
  final String activeTabId;
  final ValueChanged<NavigationItemConfig>? onItemTap;

  const DealOneSectionBottomNav({
    super.key,
    required this.sectionId,
    this.activeTabId = 'home',
    this.onItemTap,
  });

  void _navigateToItem(
    BuildContext context,
    WidgetRef ref,
    NavigationItemConfig item,
  ) {
    if (item.id == activeTabId) return;
    if (onItemTap != null) {
      onItemTap!(item);
      return;
    }

    if (item.id == SectionNavigationRegistry.exploreTabId &&
        item.destination == RouteNames.search) {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
        categorySlug: item.categoryContext ?? sectionId,
      );
      context.push(RouteNames.search);
      return;
    }

    if (item.id == SectionNavigationRegistry.homeTabId ||
        item.id == SectionNavigationRegistry.mapTabId) {
      context.go(item.destination);
      return;
    }

    context.push(item.destination);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = ref.watch(accountCapabilitiesProvider);
    final config = ref.watch(sectionNavigationConfigProvider(sectionId));
    final items = config.items;
    final activeIndex = items.indexWhere((i) => i.id == activeTabId);
    final safeIndex = activeIndex < 0 ? 0 : activeIndex;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isSmall = context.isSmallPhone;
    final hPad = context.horizontalScreenPadding;

    // Hide cleanly when software keyboard is open.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(hPad, 6, hPad, 10),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DealOneBottomNavTokens.maxBarWidth,
            ),
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.2,
              child: Container(
                key: Key('section_bottom_nav_$sectionId'),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 6.0 : 10.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: DealOneBottomNavTokens.barBackgroundOf(context),
                  borderRadius: BorderRadius.circular(
                    DealOneBottomNavTokens.floatingBarRadius,
                  ),
                  border: Border.all(
                    color: DealOneBottomNavTokens.barBorderOf(context),
                    width: 1.0,
                  ),
                  boxShadow: DealOneBottomNavTokens.floatingBarShadowOf(
                    context,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      ActiveNavigationIndicator(
                        activeIndex: safeIndex,
                        itemCount: items.length,
                      ),
                      Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isRoleDependentSlot =
                              item.visibilityRule ==
                                  NavigationVisibilityRule.buyerOnly ||
                              item.visibilityRule ==
                                  NavigationVisibilityRule.sellerOnly;

                          // Never flash Favorites then swap to Seller Action while
                          // backend account permissions are loading.
                          if (isRoleDependentSlot && capabilities.isLoading) {
                            return Expanded(
                              child: _RoleSlotLoadingPlaceholder(
                                key: const Key('section_nav_role_slot_loading'),
                                isSmall: isSmall,
                              ),
                            );
                          }

                          final isActive = index == safeIndex;
                          final label = item.localizedLabel(isArabic);
                          final badgeCount = ref.watch(
                            navigationBadgeCountProvider(item.badgeKey),
                          );
                          final fgColor = isActive
                              ? DealOneBottomNavTokens.activeForegroundOf(
                                  context,
                                )
                              : DealOneBottomNavTokens.inactiveForegroundOf(
                                  context,
                                );

                          return Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Semantics(
                                key: ValueKey<String>(
                                  '${item.id}_${isActive ? 1 : 0}',
                                ),
                                button: true,
                                selected: isActive,
                                label: label,
                                child: InkWell(
                                  key: Key('section_nav_tab_${item.id}'),
                                  onTap: () =>
                                      _navigateToItem(context, ref, item),
                                  borderRadius: BorderRadius.circular(
                                    DealOneBottomNavTokens.activePillRadius,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 6,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _NavIconWithBadge(
                                          icon: isActive
                                              ? item.activeIcon
                                              : item.inactiveIcon,
                                          size: isSmall ? 20 : 22,
                                          color: fgColor,
                                          badgeCount: badgeCount,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: DealOneBottomNavTokens
                                                .fontFamily,
                                            fontSize: isSmall ? 10.5 : 11.5,
                                            fontWeight: isActive
                                                ? DealOneBottomNavTokens
                                                    .activeFontWeight
                                                : DealOneBottomNavTokens
                                                    .inactiveFontWeight,
                                            color: fgColor,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final int badgeCount;

  const _NavIconWithBadge({
    required this.icon,
    required this.size,
    required this.color,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeCount <= 0) {
      return Icon(icon, size: size, color: color);
    }

    final badgeText = badgeCount > 99 ? '99+' : '$badgeCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: size, color: color),
        PositionedDirectional(
          top: -5,
          end: -9,
          child: Container(
            key: const Key('section_nav_badge'),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: DealOneBottomNavTokens.barBackgroundOf(context),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleSlotLoadingPlaceholder extends StatelessWidget {
  final bool isSmall;

  const _RoleSlotLoadingPlaceholder({
    super.key,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = DealOneBottomNavTokens.inactiveForegroundOf(
      context,
    ).withValues(alpha: 0.18);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmall ? 18 : 20,
            height: isSmall ? 18 : 20,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: isSmall ? 30 : 36,
            height: 8,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
