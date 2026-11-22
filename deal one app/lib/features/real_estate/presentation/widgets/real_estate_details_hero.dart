import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Full-bleed hero image carousel matching `Real Estate Details.png`.
class RealEstateDetailsHero extends StatefulWidget {
  final ListingItem item;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final ValueChanged<int> onOpenGallery;

  const RealEstateDetailsHero({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onOpenGallery,
  });

  @override
  State<RealEstateDetailsHero> createState() => _RealEstateDetailsHeroState();
}

class _RealEstateDetailsHeroState extends State<RealEstateDetailsHero> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final images = widget.item.media
        .where((m) => m.mediaType.toLowerCase() != 'video')
        .toList();
    final isRent = widget.item.listingKind.toLowerCase() == 'rent' ||
        widget.item.categorySlug.contains('rent');
    final heroHeight =
        (MediaQuery.sizeOf(context).height * 0.36).clamp(240.0, 360.0);

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isNotEmpty)
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => widget.onOpenGallery(index),
                  child: Hero(
                    tag: 'listing-photo-${widget.item.id}-$index',
                    child: AppNetworkImage(
                      imageUrl: images[index].publicUrl,
                      fit: BoxFit.cover,
                      enableRetry: true,
                      fallbackIcon: Icons.home_work_outlined,
                    ),
                  ),
                );
              },
            )
          else
            Container(
              color: DealOneTokens.softTileBgOf(context),
              child: const Center(
                child: Icon(
                  Icons.home_work_outlined,
                  size: 64,
                  color: DealOneTokens.navy,
                ),
              ),
            ),

          // Subtle top & bottom gradient scrims
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Top Floating Action Row
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: widget.onBack,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeroCircleButton(
                        icon: widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: widget.isFavorite
                            ? DealOneTokens.dangerRed
                            : DealOneTokens.navy,
                        onTap: widget.onToggleFavorite,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeroCircleButton(
                        icon: Icons.share_outlined,
                        onTap: widget.onShare,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Status & "View All Photos" Pills
          PositionedDirectional(
            bottom: AppSpacing.md,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DealOneTokens.navy.withValues(alpha: 0.88),
                    borderRadius: AppRadii.full,
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
                      const SizedBox(width: 6),
                      Text(
                        isRent
                            ? (isArabic ? 'للإيجار الفوري' : 'For Rent')
                            : (isArabic ? 'للبيع' : 'For Sale'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (images.isNotEmpty)
                  Material(
                    color: DealOneTokens.navy.withValues(alpha: 0.82),
                    borderRadius: AppRadii.full,
                    child: InkWell(
                      key: const Key('real_estate_open_gallery_pill'),
                      onTap: () => widget.onOpenGallery(_currentIndex),
                      borderRadius: AppRadii.full,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                              isArabic
                                  ? '${_currentIndex + 1}/${images.length} عرض كل الصور'
                                  : '${_currentIndex + 1}/${images.length} All Photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _HeroCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? DealOneTokens.navy,
          ),
        ),
      ),
    );
  }
}
