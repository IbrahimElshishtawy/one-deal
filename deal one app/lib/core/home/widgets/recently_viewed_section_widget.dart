import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/home/providers/recently_viewed_provider.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Displays recently viewed real listings for a specific category.
/// Automatically collapses to [SizedBox.shrink] when no items have been viewed.
class RecentlyViewedSectionWidget extends ConsumerWidget {
  final String categorySlug;
  final String? titleAr;
  final String? titleEn;

  const RecentlyViewedSectionWidget({
    super.key,
    required this.categorySlug,
    this.titleAr,
    this.titleEn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(categoryRecentlyViewedProvider(categorySlug));
    if (items.isEmpty) return const SizedBox.shrink();

    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;

    return Column(
      key: Key('recently_viewed_section_$categorySlug'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DealOneSectionHeader(
          title: isArabic
              ? (titleAr ?? 'شاهدتها مؤخراً')
              : (titleEn ?? 'Recently Viewed'),
          trailingIcon: Icons.history_rounded,
        ),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final entry = items[index];
              return Material(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.push(
                    RouteNames.listingDetail.replaceFirst(':id', entry.id),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 230,
                    padding: const EdgeInsets.all(10),
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
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 78,
                            height: 92,
                            child: (entry.imageUrl != null &&
                                    entry.imageUrl!.trim().isNotEmpty)
                                ? AppNetworkImage(
                                    imageUrl: entry.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: DealOneDesignColors.navy
                                        .withValues(alpha: 0.08),
                                    child: const Icon(Icons.image_outlined),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : DealOneDesignColors.navy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatDealOnePrice(
                                  entry.price,
                                  currency: entry.currency,
                                  isArabic: isArabic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: DealOneDesignColors.amberPrice,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
