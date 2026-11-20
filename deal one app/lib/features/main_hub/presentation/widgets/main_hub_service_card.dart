import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/deal_one_section_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../listings/domain/entities/listing_entity.dart';

/// Popular Service / Listing Card matching `Home 1 - Main Hub.png`
/// and `Home 4 - Services and Engineering.png`:
/// - Top padded rounded image with top-right (start in RTL) dark navy category pill.
/// - Title + subtitle + amber price.
/// - Bottom row with overlapping reviewer avatars (`+115`), star icon, and `4.9` score.
class MainHubPopularCard extends StatelessWidget {
  final ListingItem item;

  const MainHubPopularCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeText = isArabic ? item.categoryNameAr : item.categoryNameEn;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/listings/${item.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
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
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Proportional rounded image with top-right navy category pill
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.primaryImageUrl != null &&
                              item.primaryImageUrl!.isNotEmpty)
                            Image.network(
                              item.primaryImageUrl!,
                              fit: BoxFit.cover,
                              cacheWidth: 420,
                              errorBuilder: (_, _, _) => Container(
                                color: DealOneDesignColors.navy.withValues(
                                  alpha: 0.1,
                                ),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: DealOneDesignColors.navy,
                                ),
                              ),
                            )
                          else
                            Container(
                              color: DealOneDesignColors.navy.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.handyman_outlined,
                                color: DealOneDesignColors.navy,
                              ),
                            ),
                          if (badgeText.isNotEmpty)
                            PositionedDirectional(
                              top: 6,
                              start: 6,
                              end: 6,
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DealOneDesignColors.navy.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    badgeText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : DealOneDesignColors.navy,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          item.description.isNotEmpty
                              ? item.description
                              : item.localizedLocation(isArabic ? 'ar' : 'en'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                      ),
                      DealOneLivePriceText(
                        listingId: item.id,
                        cachedPrice: item.price,
                        currency: item.currency,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: DealOneDesignColors.amberPrice,
                        ),
                      ),
                      // Bottom Row matching PNG: overlapping avatars (+115) + star + 4.9
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Flexible(child: _ReviewerAvatarsPill()),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.isVerified ? '4.9' : '4.8',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ReviewerAvatarsPill extends StatelessWidget {
  const _ReviewerAvatarsPill();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Icon(
                Icons.person,
                size: 11,
                color: DealOneDesignColors.navy,
              ),
            ),
          ),
          PositionedDirectional(
            start: 11,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Icon(
                Icons.person,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
          PositionedDirectional(
            start: 22,
            child: Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Text(
                '+115',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  color: DealOneDesignColors.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
