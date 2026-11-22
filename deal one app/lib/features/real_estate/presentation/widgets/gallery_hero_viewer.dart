import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Swipeable Hero photo viewer with counter, fullscreen expand, prev/next arrows,
/// and caption pill matching `Photo Gallery.png`.
class GalleryHeroViewer extends StatelessWidget {
  final String listingId;
  final List<ListingMedia> images;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenFullscreen;

  const GalleryHeroViewer({
    super.key,
    required this.listingId,
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onOpenFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final height = (MediaQuery.sizeOf(context).height * 0.34).clamp(220.0, 340.0);

    return ClipRRect(
      borderRadius: AppRadii.xl,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final media = images[index];
                return GestureDetector(
                  onTap: onOpenFullscreen,
                  child: Hero(
                    tag: 'listing-photo-$listingId-$index',
                    child: AppNetworkImage(
                      imageUrl: media.publicUrl,
                      fit: BoxFit.cover,
                      enableRetry: true,
                      fallbackIcon: Icons.broken_image_outlined,
                    ),
                  ),
                );
              },
            ),

            // Counter Badge (1 / N)
            PositionedDirectional(
              top: AppSpacing.md,
              start: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DealOneTokens.navy.withValues(alpha: 0.84),
                  borderRadius: AppRadii.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${currentIndex + 1} / ${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fullscreen Expand Button
            PositionedDirectional(
              top: AppSpacing.md,
              end: AppSpacing.md,
              child: Material(
                color: DealOneTokens.navy.withValues(alpha: 0.78),
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('gallery_fullscreen_button'),
                  onTap: onOpenFullscreen,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Prev / Next Arrows
            if (images.length > 1) ...[
              if (currentIndex > 0)
                PositionedDirectional(
                  start: AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowCircleButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => pageController.previousPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                ),
              if (currentIndex < images.length - 1)
                PositionedDirectional(
                  end: AppSpacing.md,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowCircleButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => pageController.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                ),
            ],

            // Bottom Caption Pill
            Positioned(
              bottom: AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DealOneTokens.navy.withValues(alpha: 0.8),
                    borderRadius: AppRadii.full,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: DealOneTokens.amberWarm,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isArabic
                              ? 'صورة العقار ${currentIndex + 1}'
                              : 'Property Photo ${currentIndex + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: DealOneTokens.navy),
        ),
      ),
    );
  }
}
