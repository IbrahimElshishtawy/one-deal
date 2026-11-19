import 'package:flutter/material.dart';

import '../../animations/onboarding_motion_controller.dart';
import '../../theme/auth_design_tokens.dart';
import 'onboarding_slide_data.dart';

/// Animated staggered text block (category subtitle pill, title, description)
/// positioned in the bottom text-safe zone with adaptive typography and
/// automatic RTL/LTR alignment.
class OnboardingTextContent extends StatelessWidget {
  final OnboardingSlideData slide;
  final OnboardingMotionController motion;

  const OnboardingTextContent({
    super.key,
    required this.slide,
    required this.motion,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;
    final accentColor = AuthDesignTokens.onboardingCtaBlue;

    final subtitleChip = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const Key('onboarding_slide_subtitle'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Text(
          slide.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompact ? 11.5 : 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    final titleWidget = Text(
      slide.title,
      key: const Key('onboarding_slide_title'),
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: isCompact ? 19.5 : 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.32,
      ),
    );

    final descriptionWidget = Text(
      slide.description,
      key: const Key('onboarding_slide_description'),
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: isCompact ? 13.5 : 14.5,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.90),
        height: 1.55,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: motion.subtitleFade,
          child: SlideTransition(
            position: motion.subtitleSlide,
            child: subtitleChip,
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: motion.titleFade,
          child: SlideTransition(
            position: motion.titleSlide,
            child: titleWidget,
          ),
        ),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: motion.descriptionFade,
          child: SlideTransition(
            position: motion.descriptionSlide,
            child: descriptionWidget,
          ),
        ),
      ],
    );
  }
}
