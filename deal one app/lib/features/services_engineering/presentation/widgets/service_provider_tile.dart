import 'package:flutter/material.dart';

import 'package:market_space/core/marketplace/section_home_models.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Verified Service Provider Card matching `الشركاء والتوكيلات المعتمدة`
/// in `Home 4 - Services and Engineering.png`.
class ServicesProviderTile extends StatelessWidget {
  final SectionProviderItem provider;
  final VoidCallback onBookTap;

  const ServicesProviderTile({
    super.key,
    required this.provider,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmall = context.isSmallPhone;
    final hPad = context.horizontalScreenPadding;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 5),
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmall ? 20 : 24,
            backgroundColor: DealOneDesignColors.navy,
            backgroundImage: (provider.logoUrl != null &&
                    provider.logoUrl!.isNotEmpty)
                ? NetworkImage(provider.logoUrl!)
                : null,
            child: (provider.logoUrl == null || provider.logoUrl!.isEmpty)
                ? Text(
                    provider.displayName.isNotEmpty
                        ? provider.displayName.characters.first
                        : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          SizedBox(width: isSmall ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        provider.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isSmall ? 12.5 : 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : DealOneDesignColors.navy,
                        ),
                      ),
                    ),
                    if (provider.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic ? provider.specialtyAr : provider.specialtyEn,
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneDesignColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onBookTap,
                icon: const Icon(Icons.calendar_today_outlined, size: 12),
                label: Text(
                  isArabic ? 'احجز الآن' : 'Book Now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    provider.isVerified ? '4.9' : '4.7',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '(${provider.listingsCount})',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
