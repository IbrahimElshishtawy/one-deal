import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/navigation/drawer/models/drawer_item_config.dart';
import 'package:market_space/core/navigation/drawer/providers/drawer_providers.dart';
import 'package:market_space/core/navigation/drawer/widgets/category_switcher_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_account_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_divider_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_footer_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_header_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_item_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_section_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_support_widget.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_settings_sheet.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

/// Modular Navigation Drawer container assembling independent single-responsibility
/// widgets for all 6 Deal One categories.
///
/// Uses GoRouter Named Routes (`pushNamed` / `goNamed`) and Riverpod
/// [drawerConfigProvider] + [accountCapabilitiesProvider].
class DealOneNavigationDrawer extends ConsumerWidget {
  final String activeCategorySlug;
  final ValueChanged<String>? onRouteSelected;

  const DealOneNavigationDrawer({
    super.key,
    required this.activeCategorySlug,
    this.onRouteSelected,
  });

  void _closeDrawer(BuildContext context) {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _handleItemTap(
    BuildContext context,
    WidgetRef ref,
    DrawerItemConfig item,
  ) {
    _closeDrawer(context);

    switch (item.action) {
      case DrawerItemAction.openSettingsSheet:
        showProfileSettingsSheet(context);
        return;
      case DrawerItemAction.logout:
        ref.read(sessionProvider.notifier).logout();
        return;
      case DrawerItemAction.openCategorySearch:
        ref.read(searchQueryProvider.notifier).state = '';
        ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
          categorySlug: item.categoryContext ?? activeCategorySlug,
        );
        if (onRouteSelected != null) {
          onRouteSelected!(RouteNames.search);
        } else {
          context.pushNamed(RouteNames.searchName);
        }
        return;
      case DrawerItemAction.navigateRoute:
        if (onRouteSelected != null) {
          if (item.route.isNotEmpty) onRouteSelected!(item.route);
          return;
        }
        if (item.routeName != null && item.routeName!.isNotEmpty) {
          context.pushNamed(
            item.routeName!,
            pathParameters: item.pathParameters,
            queryParameters: item.queryParameters,
          );
        } else if (item.route.isNotEmpty) {
          context.push(item.route);
        }
        return;
    }
  }

  void _handleCategorySwitch(
    BuildContext context,
    DrawerCategoryEntry entry,
  ) {
    _closeDrawer(context);
    if (entry.slug == MapCategoryRegistry.normalizeSlug(activeCategorySlug)) {
      return;
    }
    if (onRouteSelected != null) {
      onRouteSelected!(entry.route);
    } else {
      context.goNamed(entry.routeName);
    }
  }

  void _handleMainHubTap(BuildContext context) {
    _closeDrawer(context);
    if (onRouteSelected != null) {
      onRouteSelected!(RouteNames.root);
    } else {
      context.goNamed(RouteNames.rootName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final normalizedSlug = MapCategoryRegistry.normalizeSlug(activeCategorySlug);
    final capabilities = ref.watch(accountCapabilitiesProvider);
    final accountsAsync = ref.watch(myAccountsProvider);
    final config = ref.watch(drawerConfigProvider(normalizedSlug));
    final userName = ref.watch(activeUserDisplayNameProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.84).clamp(276.0, 360.0);

    return Drawer(
      key: Key('deal_one_navigation_drawer_$normalizedSlug'),
      width: drawerWidth,
      backgroundColor: DealOneTokens.pageBgOf(context),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            // 1. Account Header
            DrawerHeaderWidget(
              isArabic: isArabic,
              userName: userName,
              capabilities: capabilities,
              accountsError: accountsAsync.hasError ? accountsAsync.error : null,
              onRetryAccounts: () => ref.invalidate(myAccountsProvider),
              onSwitchAccount: (account) {
                ref.read(activeAccountProvider.notifier).state = account;
              },
              onSignInTap: () {
                _closeDrawer(context);
                if (onRouteSelected != null) {
                  onRouteSelected!(RouteNames.login);
                } else {
                  context.pushNamed(RouteNames.loginName);
                }
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // 2. Category Switcher
            CategorySwitcherWidget(
              activeCategorySlug: normalizedSlug,
              categories: config.categories,
              isArabic: isArabic,
              onCategorySelected: (entry) =>
                  _handleCategorySwitch(context, entry),
              onMainHubSelected: () => _handleMainHubTap(context),
            ),

            const DrawerDividerWidget(),

            // 3. Current Category Actions (Capability-Gated)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: capabilities.isLoading
                  ? _CategoryActionsLoadingSkeleton(
                      key: const Key('drawer_actions_loading'),
                      isArabic: isArabic,
                    )
                  : config.categoryActions.isEmpty
                      ? _CategoryActionsEmptyState(
                          key: const Key('drawer_actions_empty'),
                          isArabic: isArabic,
                        )
                      : DrawerSectionWidget(
                          key: ValueKey<String>(
                            'actions_${normalizedSlug}_${config.categoryActions.length}',
                          ),
                          title: isArabic
                              ? 'إجراءات القسم الحالي'
                              : 'Current Category Actions',
                          icon: Icons.bolt_rounded,
                          children: config.categoryActions
                              .map(
                                (item) => DrawerItemWidget(
                                  item: item,
                                  isArabic: isArabic,
                                  onTap: () =>
                                      _handleItemTap(context, ref, item),
                                ),
                              )
                              .toList(),
                        ),
            ),

            const DrawerDividerWidget(),

            // 4. Account Management
            DrawerAccountWidget(
              items: config.accountManagementItems,
              isArabic: isArabic,
              onItemTap: (item) => _handleItemTap(context, ref, item),
              onSettingsTap: () {
                _closeDrawer(context);
                showProfileSettingsSheet(context);
              },
            ),

            const DrawerDividerWidget(),

            // 5. Help & Legal
            DrawerSupportWidget(
              items: config.helpAndLegalItems,
              isArabic: isArabic,
              onItemTap: (item) => _handleItemTap(context, ref, item),
            ),

            const SizedBox(height: AppSpacing.md),

            // 6. Footer & Sign Out
            DrawerFooterWidget(
              isAuthenticated: capabilities.isAuthenticated,
              isArabic: isArabic,
              onLogout: () {
                _closeDrawer(context);
                ref.read(sessionProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryActionsLoadingSkeleton extends StatelessWidget {
  final bool isArabic;

  const _CategoryActionsLoadingSkeleton({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        DealOneTokens.textSecondaryOf(context).withValues(alpha: 0.14);
    return DrawerSectionWidget(
      title: isArabic ? 'إجراءات القسم الحالي' : 'Current Category Actions',
      icon: Icons.bolt_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: List.generate(
              2,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i == 0 ? 10 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: AppRadii.sm,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryActionsEmptyState extends StatelessWidget {
  final bool isArabic;

  const _CategoryActionsEmptyState({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return DrawerSectionWidget(
      title: isArabic ? 'إجراءات القسم الحالي' : 'Current Category Actions',
      icon: Icons.bolt_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            isArabic
                ? 'سجّل الدخول أو فعّل حسابك التجاري للوصول لإجراءات إضافية في هذا القسم.'
                : 'Sign in or activate a verified business account for additional tools in this section.',
            style: TextStyle(
              fontSize: 12.5,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
