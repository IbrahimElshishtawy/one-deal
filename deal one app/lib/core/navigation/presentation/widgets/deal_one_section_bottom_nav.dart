import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/navigation/config/deal_one_navigation_tokens.dart';
import 'package:market_space/core/navigation/config/navigation_item_config.dart';
import 'package:market_space/core/navigation/config/section_navigation_registry.dart';
import 'package:market_space/core/navigation/presentation/widgets/active_navigation_indicator.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

/// Unified Bottom Navigation bar for Deal One's 6 category sections.
/// Always includes the fixed Universal Map tab (`الخريطة` / `Map`) bound to
/// the active category's route `/map/<sectionId>`.
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

  String _localizedLabel(NavigationItemConfig item, bool isArabic) {
    if (isArabic) return item.label;
    switch (item.id) {
      case 'home':
        return 'Home';
      case 'map':
        return 'Map';
      case 'explore':
        return 'Explore';
      case 'favorites':
        return 'Saved';
      case 'profile':
        return 'Profile';
      default:
        return item.label;
    }
  }

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

    if (item.id == 'explore' && item.destination == RouteNames.search) {
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
        categorySlug: sectionId,
      );
      context.push(RouteNames.search);
      return;
    }

    if (item.id == 'home' || item.id == SectionNavigationRegistry.mapTabId) {
      context.go(item.destination);
      return;
    }

    context.push(item.destination);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = SectionNavigationRegistry.getConfig(sectionId);
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
                          final isActive = index == safeIndex;
                          final label = _localizedLabel(item, isArabic);
                          final fgColor = isActive
                              ? DealOneBottomNavTokens.activeForegroundOf(
                                  context,
                                )
                              : DealOneBottomNavTokens.inactiveForegroundOf(
                                  context,
                                );

                          return Expanded(
                            child: Semantics(
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isActive
                                            ? item.activeIcon
                                            : item.inactiveIcon,
                                        size: isSmall ? 20 : 22,
                                        color: fgColor,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily:
                                              DealOneBottomNavTokens.fontFamily,
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
