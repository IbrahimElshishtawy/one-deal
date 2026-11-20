import 'package:flutter/material.dart';

import '../../features/listings/domain/entities/listing_entity.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Hero Promotional Banner Carousel matching Homes 1, 3, 4, 5, 6, 7 reference PNGs:
/// - Top-left (end in RTL) dark navy pill badge + optional top-right countdown timer.
/// - Right-aligned bold white headline + subtitle.
/// - Bottom-right white CTA pill button (`تصفح المواد →`) + bottom-left pagination dots
///   (active dark navy stadium pill with white border + 3 white circles).
class DealOnePromoBannerCarousel extends StatefulWidget {
  final List<HomePromotion> promotions;
  final ValueChanged<HomePromotion> onActionTap;
  final String? countdownText;

  const DealOnePromoBannerCarousel({
    super.key,
    required this.promotions,
    required this.onActionTap,
    this.countdownText,
  });

  @override
  State<DealOnePromoBannerCarousel> createState() =>
      _DealOnePromoBannerCarouselState();
}

class _DealOnePromoBannerCarouselState
    extends State<DealOnePromoBannerCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promotions.isEmpty) return const SizedBox.shrink();
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final dotCount = widget.promotions.length < 4 ? 4 : widget.promotions.length;

    return SizedBox(
      height: context.responsivePromoBannerHeight,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.promotions.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, index) {
          final promo = widget.promotions[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (promo.imageUrl.isNotEmpty)
                    Image.network(
                      promo.imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      errorBuilder: (_, _, _) => Container(
                        color: DealOneDesignColors.navy,
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [Color(0xFF283B5B), Color(0xFF131F33)],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.22),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Row: Countdown (start/right) & Navy Pill Badge (end/left)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.countdownText != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.52),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    widget.countdownText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: DealOneDesignColors.navy.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isArabic ? promo.badgeAr : promo.badgeEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Middle Title & Subtitle
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? promo.titleAr : promo.titleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Flexible(
                                child: Text(
                                  isArabic
                                      ? promo.subtitleAr
                                      : promo.subtitleEn,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Row: White CTA Button (start/right) & Carousel Dots (end/left)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: DealOneDesignColors.navy,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => widget.onActionTap(promo),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  isArabic ? promo.ctaAr : promo.ctaEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(dotCount, (dotIdx) {
                                final isActive =
                                    (_currentIndex % dotCount) == dotIdx;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2.5,
                                  ),
                                  width: isActive ? 18 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? DealOneDesignColors.navy
                                        : Colors.white.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isActive
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
