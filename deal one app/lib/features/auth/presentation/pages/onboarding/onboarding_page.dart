import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_localization.dart';
import '../../../../../core/routing/route_names.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/onboarding/onboarding_bottom_controls.dart';
import '../../widgets/onboarding/onboarding_illustration.dart';
import '../../widgets/onboarding/onboarding_slide_data.dart';

/// 3-screen Deal One Onboarding flow faithfully reproducing:
/// - `Onboarding 1 _Real Estate and Cars_.png`
/// - `Onboarding 2 _Home services, construction materials, and electrical supplies_.png`
/// - `Onboarding 3 _Clothing, accessories, appliances, and decor_.png`
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
    final state = ref.watch(onboardingControllerProvider);
    final slides = OnboardingSlideData.localizedSlides(context);
    final activeSlide = slides[state.currentPage];
    final l10n = AppLocalization.of(context);
    final isDark = AuthDesignTokens.isDark(context);

    return Scaffold(
      backgroundColor: AuthDesignTokens.onboardingScrimBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed swipeable onboarding slides
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16, left: 16),
                child: activeSlide.showSkip
                    ? TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed: state.isSubmitting
                            ? null
                            : _handleSkipToAuth,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white
                              : AuthDesignTokens.lightTextPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(48, 40),
                        ),
                        child: Text(
                          l10n.authSkip,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AuthDesignTokens.lightTextPrimary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // Bottom foreground overlay: title, description, 3-bar indicator, blue CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AuthDesignTokens.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Column(
                            key: ValueKey<int>(state.currentPage),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                activeSlide.title,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                activeSlide.description,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.90),
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
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
          ),
        ],
      ),
    );
  }
}
