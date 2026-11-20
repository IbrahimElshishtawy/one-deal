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

/// Shared Deal One Marketplace Header matching the 7 Home designs.
/// Adapts smoothly across 320dp small phones, standard phones, tablets,
/// RTL/LTR, and up to 2.0x text scaling without overflow.
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
        (isArabic ? 'مصطفى هيكل' : 'Deal One User');
    final selectedGov = ref.watch(selectedGovernorateProvider);
    final selectedCity = ref.watch(selectedCityProvider);

    final locationDisplay = selectedCity != null
        ? '${isArabic ? selectedGov?.nameAr ?? '' : selectedGov?.nameEn ?? ''} - ${isArabic ? selectedCity.nameAr : selectedCity.nameEn}'
        : selectedGov != null
            ? (isArabic ? selectedGov.nameAr : selectedGov.nameEn)
            : (isArabic ? 'الغربية - طنطا' : 'All Egypt');

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(hPad, 12, hPad, 4),
      child: Row(
        children: [
          // User Avatar + Deal One mini badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: isSmall ? 20 : 24,
                backgroundColor: DealOneDesignColors.navy,
                child: Text(
                  userName.isNotEmpty ? userName.characters.first : 'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 15 : 18,
                  ),
                ),
              ),
              PositionedDirectional(
                bottom: -4,
                start: 2,
                end: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'ديل ون',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: DealOneDesignColors.navy,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: isSmall ? 8 : 12),

          // Name + Location Selector (and optional section badge)
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
                          fontSize: isSmall ? 14 : 15.5,
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
                              alpha: isDark ? 0.45 : 0.1,
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
                        Icons.location_on_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.white70
                            : DealOneDesignColors.navy,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          locationDisplay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: AppColors.textMutedOf(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isSmall ? 6 : 8),

          // Favorites / Basket button
          _DealOneSquareIconButton(
            icon: Icons.shopping_basket_outlined,
            tooltip: isArabic ? 'المفضلة والسلة' : 'Favorites & Basket',
            size: isSmall ? 38 : 42,
            onTap: () => context.push(RouteNames.favorites),
          ),
          SizedBox(width: isSmall ? 6 : 8),

          // Back to Main Hub (on Section Homes) OR Language/Menu toggle (on Main Hub)
          if (showBackToHub)
            _DealOneSquareIconButton(
              icon: Icons.arrow_back_rounded,
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
                    : Colors.black.withValues(alpha: 0.06),
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
              size: 20,
              color: isDark ? Colors.white : DealOneDesignColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
