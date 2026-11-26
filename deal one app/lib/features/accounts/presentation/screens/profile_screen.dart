import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/presentation/widgets/deal_one_navigation_shell.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_bottom_nav.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_business_banner.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_menu_card.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_quick_stats_row.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_settings_sheet.dart';
import 'package:market_space/features/accounts/presentation/widgets/profile_user_card.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/badges/verification_badges.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

/// Profile Screen matching `Profile.png` and connected to real Deal One backend endpoints:
/// `GET /users/me`, `GET /accounts/my-accounts`, `GET /favorites`, `GET /bookings`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.authL10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final session = ref.watch(sessionProvider);
    final insideShell = DealOneNavigationShellScope.isInsideShell(context);

    if (!session.isAuthenticated) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        bottomNavigationBar: insideShell
            ? null
            : const ProfileBottomNav(activeIndex: 3),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: l10n.profileTitleGuest,
                showBackButton: Navigator.of(context).canPop(),
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.account_circle_outlined,
                  title: l10n.profileGuestHeadline,
                  description: isArabic
                      ? 'سجّل الدخول لإدارة حسابك، متابعة محادثاتك ومعايناتك، والوصول لمفضلتك.'
                      : 'Sign in to manage your account, chats, viewings, and saved properties.',
                  actionLabel: l10n.profileLoginWithPhone,
                  actionIcon: Icons.login_rounded,
                  onAction: () => context.push(RouteNames.login),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalScreenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: TextButton.icon(
                  onPressed: () => showProfileSettingsSheet(context),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    isArabic
                        ? 'الإعدادات (اللغة، المظهر)'
                        : 'Settings (Language, Theme)',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hPad = context.horizontalScreenPadding;
    final profileAsync = ref.watch(userProfileProvider);
    final accountsAsync = ref.watch(myAccountsProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final bookingsState = ref.watch(bookingsProvider);
    final conversationsAsync = ref.watch(conversationsListProvider);
    final unreadNotificationsCount = ref.watch(
      userNotificationsProvider.select((s) => s.unreadCount),
    );
    final selectedGov = ref.watch(selectedGovernorateProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final locationDisplay = selectedCity != null
        ? '${isArabic ? selectedGov?.nameAr ?? '' : selectedGov?.nameEn ?? ''} - ${isArabic ? selectedCity.nameAr : selectedCity.nameEn}'
        : selectedGov != null
            ? (isArabic ? selectedGov.nameAr : selectedGov.nameEn)
            : (isArabic ? 'الغربية - طنطا' : 'Gharbia - Tanta');

    final bookingItems = bookingsState.items.valueOrNull ?? const [];
    final activeViewingsCount = bookingItems
        .where((b) => b.status.name != 'cancelled' && b.status.name != 'rejected')
        .length;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      bottomNavigationBar: insideShell
          ? null
          : const ProfileBottomNav(activeIndex: 3),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: DealOneTokens.navy,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(myAccountsProvider);
            await ref.read(bookingsProvider.notifier).loadBookings(refresh: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: DealOneSubPageHeader(
                  title: isArabic ? 'الملف الشخصي' : 'Profile',
                  showBackButton: Navigator.of(context).canPop(),
                  trailing: _NotificationBellButton(
                    hasUnread: unreadNotificationsCount > 0,
                    onTap: () => context.push(RouteNames.globalNotifications),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  AppSpacing.sm,
                  hPad,
                  AppSpacing.xxxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. User Summary Card
                          profileAsync.when(
                            loading: () => Container(
                              height: 92,
                              decoration: DealOneTokens.cardDecoration(context),
                              child: const Center(
                                child: DealOneDotLoader(dotSize: 8.5),
                              ),
                            ),
                            error: (err, _) => DealOneErrorStateView(
                              error: err,
                              onRetry: () => ref.invalidate(userProfileProvider),
                            ),
                            data: (profile) => ProfileUserCard(
                              fullName: profile.fullName.isNotEmpty
                                  ? profile.fullName
                                  : l10n.profileRegisteredUser,
                              locationLabel: locationDisplay,
                              avatarUrl: profile.avatarUrl,
                              isVerified: profile.isPhoneVerified,
                              onEditTap: () =>
                                  context.push(RouteNames.editAccount),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 2. Quick Stat Cards Row (Active Viewings, Favorites, Conversations)
                          ProfileQuickStatsRow(
                            items: [
                              ProfileStatItem(
                                label: isArabic
                                    ? 'المعاينات النشطة'
                                    : 'Active Viewings',
                                icon: Icons.event_available_outlined,
                                count: activeViewingsCount,
                                highlightBadge: true,
                                onTap: () => context.go(
                                  '${RouteNames.activityHub}?tab=bookings',
                                ),
                              ),
                              ProfileStatItem(
                                label: isArabic ? 'المفضلة' : 'Favorites',
                                icon: Icons.auto_awesome_outlined,
                                count: favoriteIds.length,
                                highlightBadge: false,
                                onTap: () => context.go(RouteNames.favorites),
                              ),
                              ProfileStatItem(
                                label: isArabic ? 'المحادثات' : 'Chats',
                                icon: Icons.chat_bubble_outline_rounded,
                                count: conversationsAsync.valueOrNull?.length ?? 0,
                                highlightBadge: true,
                                onTap: () =>
                                    context.push(RouteNames.conversations),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 3. Seller Verification & Business Account Banner
                          Builder(
                            builder: (_) {
                              final verificationAsync =
                                  ref.watch(sellerVerificationBadgeProvider);
                              final vSnap = verificationAsync.valueOrNull;
                              if (vSnap != null &&
                                  vSnap.sellerStatus !=
                                      VerificationStatus.notSubmitted) {
                                return SellerVerificationSummary(
                                  snapshot: vSnap,
                                  onTrackTap: () => context.push(
                                    RouteNames.sellerVerificationTracking,
                                  ),
                                  onUpgradeTap:
                                      vSnap.capabilities.canUpgradeToBusiness
                                          ? () => context.push(
                                                RouteNames
                                                    .sellerVerificationUpgrade,
                                              )
                                          : null,
                                );
                              }
                              return ProfileBusinessBanner(
                                accounts: accountsAsync.valueOrNull ?? const [],
                                onStartNow: () => context
                                    .push(RouteNames.sellerVerification),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 4. Menu List Card
                          ProfileMenuCard(
                            primaryItems: [
                              ProfileMenuRowItem(
                                title: isArabic
                                    ? 'طلباتي ومعايناتي'
                                    : 'My Orders & Viewings',
                                icon: Icons.assignment_outlined,
                                onTap: () =>
                                    context.go(RouteNames.activityHub),
                              ),
                              ProfileMenuRowItem(
                                tileKey: const Key('profile_settings_tile'),
                                title: isArabic
                                    ? 'الإعدادات (اللغة، المظهر، الإشعارات)'
                                    : 'Settings (Language, Theme, Notifications)',
                                icon: Icons.tune_rounded,
                                onTap: () => showProfileSettingsSheet(context),
                              ),
                              ProfileMenuRowItem(
                                title: isArabic
                                    ? 'مركز المساعدة والدعم'
                                    : 'Help & Support Center',
                                icon: Icons.support_agent_rounded,
                                onTap: () => _showHelpDialog(context),
                              ),
                              ProfileMenuRowItem(
                                title: isArabic
                                    ? 'الشروط وسياسة الخصوصية'
                                    : 'Terms & Privacy Policy',
                                icon: Icons.verified_user_outlined,
                                onTap: () => context.push(RouteNames.terms),
                              ),
                            ],
                            logoutItem: ProfileMenuRowItem(
                              tileKey: const Key('profile_logout_tile'),
                              title: l10n.profileLogout,
                              icon: Icons.logout_rounded,
                              isDestructive: true,
                              onTap: () => _confirmLogout(context, ref),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'مركز المساعدة والدعم' : 'Help & Support'),
        content: Text(
          isArabic
              ? 'فريق دعم Deal One متاح لمساعدتك في جميع استفسارات العقارات والحسابات.'
              : 'Deal One support is available to assist you with listings and account questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isArabic ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Sign Out'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من تسجيل الخروج من حسابك؟'
              : 'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _NotificationBellButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasUnread;

  const _NotificationBellButton({
    required this.onTap,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.md,
      child: InkWell(
        key: const Key('profile_notifications_button'),
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            boxShadow: DealOneTokens.softShadow(context),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_rounded,
                size: 22,
                color: DealOneTokens.textPrimaryOf(context),
              ),
              if (hasUnread)
                PositionedDirectional(
                  top: 9,
                  end: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DealOneTokens.dangerRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
