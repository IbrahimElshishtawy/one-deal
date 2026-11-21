import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/onboarding/onboarding_bottom_controls.dart';
import 'package:market_space/features/auth/presentation/widgets/onboarding/onboarding_illustration.dart';
import 'package:market_space/features/auth/presentation/widgets/onboarding/onboarding_slide_data.dart';

/// 3-screen Deal One Onboarding carousel reproducing the 3 Figma exports:
/// - Onboarding 1: Real Estate and Cars
/// - Onboarding 2: Home services, construction materials, and electrical supplies
/// - Onboarding 3: Clothing, accessories, appliances, and decor
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleNextOrStart() async {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final completed = await notifier.advanceOrComplete();
    if (!mounted) return;
    if (completed) {
      context.go(RouteNames.signUp);
    } else {
      final targetPage = ref.read(onboardingControllerProvider).currentPage;
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 420),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
    }
  }

  Future<void> _handleSkipToAuth() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(RouteNames.signUp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final state = ref.watch(onboardingControllerProvider);
    final slides = OnboardingSlideData.localizedSlides(l10n);
    final activeSlide = slides[state.currentPage.clamp(0, slides.length - 1)];

    return Scaffold(
      backgroundColor: AuthDesignTokens.onboardingScrimDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: const Key('onboarding_pageview'),
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (index) {
              ref.read(onboardingControllerProvider.notifier).setPage(index);
            },
            itemBuilder: (context, index) {
              return OnboardingIllustration(slide: slides[index]);
            },
          ),

          // Top Skip action (shown on slides 1 & 2, hidden on slide 3 per Figma)
          if (activeSlide.showSkip)
            SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuthDesignTokens.spaceBase,
                    vertical: AuthDesignTokens.spaceSm,
                  ),
                  child: TextButton(
                    key: const Key('onboarding_skip_button'),
                    onPressed: state.isSubmitting ? null : _handleSkipToAuth,
                    style: TextButton.styleFrom(
                      foregroundColor: AuthDesignTokens.isDark(context)
                          ? Colors.white
                          : AuthDesignTokens.lightTextPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      l10n.onboardingSkip,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AuthDesignTokens.isDark(context)
                            ? Colors.white
                            : AuthDesignTokens.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom copy + 3-bar progress + CTA button over dark scrim
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AuthDesignTokens.maxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AuthDesignTokens.horizontalPadding,
                    AuthDesignTokens.spaceBase,
                    AuthDesignTokens.horizontalPadding,
                    AuthDesignTokens.spaceLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: Column(
                          key: ValueKey(state.currentPage),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              activeSlide.title,
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: AuthDesignTokens.spaceSm),
                            Text(
                              activeSlide.description,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AuthDesignTokens.spaceXl),
                      OnboardingBottomControls(
                        currentPage: state.currentPage,
                        totalPages: slides.length,
                        primaryLabel: activeSlide.primaryButtonLabel,
                        isSubmitting: state.isSubmitting,
                        onPrimaryPressed: _handleNextOrStart,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
