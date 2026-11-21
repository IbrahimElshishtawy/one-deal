import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/favorites/domain/entities/favorite_entity.dart';
import 'package:market_space/shared/widgets/market_widgets/safe_network_image.dart';

class FavoriteListingCard extends StatelessWidget {
  final FavoriteItem favorite;
  final VoidCallback onOpenListing;
  final VoidCallback onOpenSection;
  final VoidCallback onRemoveFavorite;

  const FavoriteListingCard({
    super.key,
    required this.favorite,
    required this.onOpenListing,
    required this.onOpenSection,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final item = favorite.listing;
    final sector = MarketplaceSectorCategory.fromCategorySlug(
      item.categorySlug,
    );

    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onOpenListing,
        borderRadius: AppRadii.lg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.lg,
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.md,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child:
                          item.primaryImageUrl != null &&
                              item.primaryImageUrl!.isNotEmpty
                          ? SafeNetworkImage(
                              imageUrl: item.primaryImageUrl!,
                              fit: BoxFit.cover,
                              fallbackIcon: Icons.photo_outlined,
                            )
                          : Container(
                              color: AppColors.surfaceSecondaryOf(context),
                              child: Icon(
                                Icons.photo_outlined,
                                color: AppColors.textMutedOf(context),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ActivityHubL10n.sectorLabel(context, sector),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.infoOf(context),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ActivityHubL10n.formatPrice(
                            item.price,
                            currency: item.currency,
                            isArabic: isArabic,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: DealOneDesignColors.amberPrice,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.favoritesRemoveAction,
                    onPressed: onRemoveFavorite,
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.errorOf(context),
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onOpenSection,
                    icon: const Icon(Icons.explore_outlined, size: 16),
                    label: Text(l10n.favoritesGoToSectionAction),
                  ),
                  TextButton.icon(
                    onPressed: onOpenListing,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(l10n.favoritesOpenListingAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
