import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Responsive 2+ column thumbnail grid matching `Photo Gallery.png`.
/// Highlights the currently viewed image with a "معروضة حالياً" badge.
class GalleryThumbnailGrid extends StatelessWidget {
  final List<ListingMedia> images;
  final int currentIndex;
  final ValueChanged<int> onSelectImage;

  const GalleryThumbnailGrid({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final cols = context.productGridColumnsForWidth();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final media = images[index];
        final isActive = index == currentIndex;

        return GestureDetector(
          onTap: () => onSelectImage(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: AppRadii.lg,
              border: Border.all(
                color: isActive
                    ? DealOneTokens.navy
                    : DealOneTokens.cardBorderOf(context),
                width: isActive ? 2.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  imageUrl: media.publicUrl,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.image_outlined,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                    ),
                  ),
                ),
                if (isActive)
                  PositionedDirectional(
                    top: 8,
                    start: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DealOneTokens.navy.withValues(alpha: 0.9),
                        borderRadius: AppRadii.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'معروضة حالياً' : 'Viewing',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                PositionedDirectional(
                  bottom: 8,
                  start: 10,
                  end: 10,
                  child: Text(
                    isArabic ? 'لقطة ${index + 1}' : 'Shot ${index + 1}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
