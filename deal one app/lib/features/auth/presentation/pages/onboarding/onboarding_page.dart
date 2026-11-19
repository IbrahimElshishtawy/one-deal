import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_localization.dart';
import '../../../../../core/routing/route_names.dart';
import '../../animations/onboarding_motion_controller.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/onboarding/cinematic_image_view.dart';
import '../../widgets/onboarding/onboarding_background.dart';
import '../../widgets/onboarding/onboarding_bottom_controls.dart';
import '../../widgets/onboarding/onboarding_slide_data.dart';
import '../../widgets/onboarding/onboarding_text_content.dart';

/// Cinematic 3-slide Deal One Onboarding experience using the exact existing
/// artwork assets (`onboarding_1.png`, `onboarding_2.png`, `onboarding_3.png`)
/// with slow Ken Burns zoom/pan, real-time cross-fade & parallax, staggered
/// text entrance, theme-aware scrims, full Arabic RTL / English LTR support,
/// and reduced-motion accessibility.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final OnboardingMotionController _motionController;
  late final ValueNotifier<double> _pageOffsetNotifier;

  bool _imagesPrecached = false;
  bool _isAnimatingPage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageOffsetNotifier = ValueNotifier<double>(0.0);
    _pageController.addListener(_handlePageScroll);
    _motionController = OnboardingMotionController(vsync: this);
    _motionController.playSlideEntrance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _motionController.setReducedMotion(disableAnimations);

    if (!_imagesPrecached) {
      _imagesPrecached = true;
      for (final assetPath in OnboardingSlideData.artworkAssetPaths) {
        precacheImage(AssetImage(assetPath), context);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    _pageOffsetNotifier.dispose();
    _motionController.dispose();
    super.dispose();
  }

  void _handlePageScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page != null && (page - _pageOffsetNotifier.value).abs() > 0.0005) {
      _pageOffsetNotifier.value = page;
    }
  }

  Future<void> _animateToPage(int targetPage) async {
    if (!_pageController.hasClients) return;
    if (_motionController.reducedMotion) {
      _pageController.jumpToPage(targetPage);
      _pageOffsetNotifier.value = targetPage.toDouble();
      return;
    }
    _isAnimatingPage = true;
    try {
      await _pageController.animateToPage(
        targetPage,
        duration: _motionController.config.pageTransitionDuration,
        curve: _motionController.config.pageTransitionCurve,
      );
    } finally {
      _isAnimatingPage = false;
    }
  }

  Future<void> _handleNextOrStart() async {
    if (_isAnimatingPage) return;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final completed = await notifier.advanceOrComplete();
    if (!mounted) return;
    if (completed) {
      context.go(RouteNames.signUp);
      return;
    }
    final targetPage = ref.read(onboardingControllerProvider).currentPage;
    await _animateToPage(targetPage);
  }

  Future<void> _handlePrevious() async {
    if (_isAnimatingPage) return;
    final moved = ref
        .read(onboardingControllerProvider.notifier)
        .previousPage();
    if (!moved || !mounted) return;
    final targetPage = ref.read(onboardingControllerProvider).currentPage;
    await _animateToPage(targetPage);
  }

  Future<void> _handleSkipToAuth() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(RouteNames.signUp);
  }

  void _onPageChanged(int index) {
    final current = ref.read(onboardingControllerProvider).currentPage;
    if (current != index) {
      ref.read(onboardingControllerProvider.notifier).setPage(index);
    }
    _motionController.playSlideEntrance();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final slides = OnboardingSlideData.localizedSlides(context);
    final activeSlide = slides[state.currentPage];
    final l10n = AppLocalization.of(context);
    final isDark = AuthDesignTokens.isDark(context);
    final reducedMotion = _motionController.reducedMotion;

    return Scaffold(
      backgroundColor: isDark
          ? AuthDesignTokens.darkBackground
          : AuthDesignTokens.onboardingScrimBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Full-screen cinematic Ken Burns + cross-fade + parallax stack
          OnboardingBackground(
            child: ValueListenableBuilder<double>(
              valueListenable: _pageOffsetNotifier,
              builder: (context, pageOffset, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: List.generate(slides.length, (index) {
                    return CinematicImageView(
                      key: ValueKey<String>(slides[index].artworkAssetPath),
                      slide: slides[index],
                      index: index,
                      pageOffset: pageOffset,
                      isActive: index == state.currentPage,
                      kenBurnsAnimation: _motionController.kenBurnsProgress,
                      config: _motionController.config,
                      reducedMotion: reducedMotion,
                    );
                  }),
                );
              },
            ),
          ),

          // Layer 2: Interactive full-screen swipe surface synced with PageController
          PageView.builder(
            key: const Key('onboarding_pageview'),
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (_, _) => const ColoredBox(color: Colors.transparent),
          ),

          // Layer 3: Top Skip action (shown on slides 1 & 2, hidden on slide 3)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 16, left: 16),
                  child: AnimatedSwitcher(
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: activeSlide.showSkip
                        ? TextButton(
                            key: const Key('onboarding_skip_button'),
                            onPressed: state.isSubmitting
                                ? null
                                : _handleSkipToAuth,
                            style: TextButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.black.withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.52),
                              foregroundColor: isDark
                                  ? Colors.white
                                  : AuthDesignTokens.lightTextPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: const Size(48, 38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              l10n.authSkip,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AuthDesignTokens.lightTextPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey<String>('no_skip'),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Layer 4: Bottom text-safe foreground overlay (subtitle, title, description, controls)
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
                        IgnorePointer(
                          child: OnboardingTextContent(
                            key: ValueKey<int>(state.currentPage),
                            slide: activeSlide,
                            motion: _motionController,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OnboardingBottomControls(
                          currentPage: state.currentPage,
                          totalPages: slides.length,
                          primaryLabel: activeSlide.primaryButtonLabel,
                          showPrevious: activeSlide.showPrevious,
                          isSubmitting: state.isSubmitting,
                          reducedMotion: reducedMotion,
                          onPrimaryPressed: _handleNextOrStart,
                          onPreviousPressed: _handlePrevious,
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
