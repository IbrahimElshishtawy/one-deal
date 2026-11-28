import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/features/accounts/presentation/providers/user_profile_providers.dart';
import 'package:market_space/features/listings/presentation/widgets/location_selector_sheet.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Shared Deal One Marketplace Header matching all 7 Home reference PNGs:
/// - Warm circular portrait avatar with bottom overlapping Deal One handshake logo badge (`assets/image/logo.png`).
/// - Authenticated user's real full name (loaded from `userProfileProvider` / `activeUserDisplayNameProvider`) + Location pin.
/// - Two white rounded-square (`12dp`) icon buttons on the opposite side (Basket & Menu/Back).
class DealOneHomeHeader extends ConsumerWidget {
  final bool showBackToHub;
  final String? sectionBadge;
  final VoidCallback? onBackPressed;

  const DealOneHomeHeader({
    super.key,
    this.showBackToHub = false,
    this.sectionBadge,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = context.isSmallPhone;
    final hPad = context.horizontalScreenPadding;
    final session = ref.watch(sessionProvider);
    final profileAsync = session.isAuthenticated
        ? ref.watch(userProfileProvider)
        : null;
    final profile = profileAsync?.valueOrNull;
    final cachedName = session.isAuthenticated
        ? ref.watch(activeUserDisplayNameProvider)?.trim()
        : null;
    final isVerifyingUser = session.isAuthenticated &&
        (profileAsync?.isLoading ?? false) &&
        profile == null;
    final hasVerificationError = session.isAuthenticated &&
        (profileAsync?.hasError ?? false) &&
        profile == null;
    final profileName = profile?.fullName.trim();
    final profilePhone = profile?.phone.trim();
    final userName = !session.isAuthenticated
        ? (isArabic ? 'مرحباً بك' : 'Welcome Guest')
        : (profileName != null && profileName.isNotEmpty)
            ? profileName
            : (cachedName != null && cachedName.isNotEmpty)
                ? cachedName
                : (profilePhone != null && profilePhone.isNotEmpty)
                    ? profilePhone
                    : (isArabic ? 'مستخدم Deal One' : 'Deal One User');
    final avatarUrl = profile?.avatarUrl;
    final selectedGov = ref.watch(selectedGovernorateProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final locationDisplay = selectedCity != null
        ? '${isArabic ? selectedGov?.nameAr ?? '' : selectedGov?.nameEn ?? ''} - ${isArabic ? selectedCity.nameAr : selectedCity.nameEn}'
        : selectedGov != null
            ? (isArabic ? selectedGov.nameAr : selectedGov.nameEn)
            : (isArabic ? 'الغربية - طنطا' : 'Gharbia - Tanta');

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(hPad, 12, hPad, 6),
      child: Row(
        children: [
          // Circular Portrait Avatar + Overlapping Deal One Logo Badge
          SizedBox(
            width: isSmall ? 46 : 54,
            height: isSmall ? 50 : 58,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: isSmall ? 44 : 52,
                  height: isSmall ? 44 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE7D2B8), Color(0xFFD2B48C)],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.person_rounded,
                              size: isSmall ? 26 : 30,
                              color: DealOneDesignColors.navy,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: isSmall ? 26 : 30,
                            color: DealOneDesignColors.navy,
                          ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  child: Container(
                    width: isSmall ? 26 : 30,
                    height: isSmall ? 20 : 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const DealOneLogo(
                      fallback: Center(
                        child: Text(
                          'DealOne',
                          style: TextStyle(
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            color: DealOneDesignColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmall ? 8 : 10),

          // User Name + Location Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 3,
                      child: isVerifyingUser
                          ? _HeaderUserNameLoading(
                              isDark: isDark,
                              isSmall: isSmall,
                            )
                          : hasVerificationError
                              ? InkWell(
                                  key: const Key('header_user_name_retry'),
                                  onTap: () =>
                                      ref.invalidate(userProfileProvider),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (cachedName != null &&
                                                  cachedName.isNotEmpty)
                                              ? cachedName
                                              : (isArabic
                                                  ? 'تعذر التحقق • إعادة'
                                                  : 'Verify account • Retry'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: isSmall ? 13.5 : 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : DealOneDesignColors.navy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.refresh_rounded,
                                        size: 15,
                                        color: isDark
                                            ? Colors.white70
                                            : DealOneDesignColors.navy,
                                      ),
                                    ],
                                  ),
                                )
                              : Text(
                                  userName,
                                  key: const Key('header_user_name_text'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isSmall ? 14.5 : 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : DealOneDesignColors.navy,
                                  ),
                                ),
                    ),
                    if (sectionBadge != null && sectionBadge!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.navy.withValues(
                              alpha: isDark ? 0.45 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sectionBadge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : DealOneDesignColors.navy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => showLocationSelectorSheet(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pin_drop_rounded,
                        size: 15,
                        color: isDark
                            ? Colors.white70
                            : DealOneDesignColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMutedOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isSmall ? 6 : 8),

          // Left button 1: Shopping Basket -> Activity & Commerce Hub
          _DealOneSquareIconButton(
            icon: Icons.shopping_basket_rounded,
            tooltip: isArabic
                ? 'مركز النشاط والتجارة'
                : 'Activity & Commerce Hub',
            size: isSmall ? 38 : 42,
            onTap: () => context.go(RouteNames.activityHub),
          ),
          SizedBox(width: isSmall ? 6 : 8),

          // Left button 2: Dynamic Navigation Drawer (when Scaffold has a drawer) or Back/Language fallback
          if (Scaffold.maybeOf(context)?.hasDrawer == true)
            _DealOneSquareIconButton(
              icon: Icons.menu_rounded,
              tooltip: isArabic ? 'القائمة' : 'Menu',
              size: isSmall ? 38 : 42,
              onTap: () => Scaffold.of(context).openDrawer(),
            )
          else if (showBackToHub)
            _DealOneSquareIconButton(
              icon: Icons.menu_rounded,
              tooltip: isArabic ? 'العودة للرئيسية' : 'Back to Main Hub',
              size: isSmall ? 38 : 42,
              onTap: onBackPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RouteNames.root);
                    }
                  },
            )
          else
            _DealOneSquareIconButton(
              icon: Icons.menu_rounded,
              tooltip: isArabic ? 'تغيير اللغة' : 'Switch Language',
              size: isSmall ? 38 : 42,
              onTap: () {
                final current = ref.read(appLocaleProvider);
                ref.read(appLocaleProvider.notifier).setLocale(
                      current.languageCode == 'ar'
                          ? const Locale('en')
                          : const Locale('ar'),
                    );
              },
            ),
        ],
      ),
    );
  }
}

class _DealOneSquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  const _DealOneSquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 21,
              color: isDark ? Colors.white : DealOneDesignColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderUserNameLoading extends StatelessWidget {
  final bool isDark;
  final bool isSmall;

  const _HeaderUserNameLoading({
    required this.isDark,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : DealOneDesignColors.navy.withValues(alpha: 0.12);
    return Row(
      key: const Key('header_user_name_loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: isSmall ? 12 : 14,
          height: isSmall ? 12 : 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? AppColors.darkTextPrimary : DealOneDesignColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            width: isSmall ? 84 : 112,
            height: isSmall ? 14 : 16,
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}
