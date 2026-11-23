import 'package:flutter/material.dart';

import 'package:market_space/core/marketplace/section_home_models.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Shared Supplier / Service Provider / Verified Seller card used across
/// Services & Engineering, Building Materials, Appliances, Cars, and Fashion.
class SupplierCardWidget extends StatelessWidget {
  final SectionProviderItem provider;
  final VoidCallback? onTap;

  const SupplierCardWidget({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specialty = isArabic && provider.specialtyAr.isNotEmpty
        ? provider.specialtyAr
        : (provider.specialtyEn.isNotEmpty
            ? provider.specialtyEn
            : provider.accountType);

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 196,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: (provider.logoUrl != null &&
                          provider.logoUrl!.trim().isNotEmpty)
                      ? AppNetworkImage(
                          imageUrl: provider.logoUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: DealOneDesignColors.navy.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: isDark
                                ? Colors.white70
                                : DealOneDesignColors.navy,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
                            color: Color(0xFF0EA5E9),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    if (provider.listingsCount > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        isArabic
                            ? '${provider.listingsCount} عرض متاح'
                            : '${provider.listingsCount} active items',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.amber.shade300
                              : DealOneDesignColors.amberPrice,
                        ),
                      ),
                    ],
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
