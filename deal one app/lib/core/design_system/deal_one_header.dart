import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/listings/presentation/widgets/location_selector_sheet.dart';
import '../../features/locations/presentation/providers/locations_providers.dart';
import '../providers/app_settings_providers.dart';
import '../providers/core_providers.dart';
import '../routing/route_names.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Shared Deal One Marketplace Header matching all 7 Home reference PNGs:
/// - Warm circular portrait avatar with bottom overlapping Deal One handshake logo badge (`assets/image/logo.png`).
/// - User Name (`مصطفي هيكل` or authenticated user) + Location pin (`الغربية - طنطا` or selected location).
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
    final userName = ref.watch(activeUserDisplayNameProvider) ??
        (isArabic ? 'مصطفي هيكل' : 'Mostafa Heikal');
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
                  child: Icon(
                    Icons.person_rounded,
                    size: isSmall ? 26 : 30,
                    color: DealOneDesignColors.navy,
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
                    child: Image.asset(
                      'assets/image/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text(
                          'ديل ون',
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
                      child: Text(
                        userName,
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

          // Left button 1: Shopping Basket
          _DealOneSquareIconButton(
            icon: Icons.shopping_basket_rounded,
            tooltip: isArabic ? 'المفضلة والسلة' : 'Favorites & Basket',
            size: isSmall ? 38 : 42,
            onTap: () => context.push(RouteNames.favorites),
          ),
          SizedBox(width: isSmall ? 6 : 8),

          // Left button 2: Menu / Back to Main Hub
          if (showBackToHub)
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
