import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/onboarding/onboarding_bottom_controls.dart';
import '../../widgets/onboarding/onboarding_illustration.dart';
import '../../widgets/onboarding/onboarding_slide_data.dart';

/// 3-screen Deal One Onboarding carousel (Design Screens 1–3).
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
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleSkipToAuth() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(RouteNames.signUp);
  }

  Future<void> _handleBrowseAsGuest() async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(RouteNames.root);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final slides = OnboardingSlideData.slides;
    final activeSlide = slides[state.currentPage];

    return Scaffold(
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AuthDesignTokens.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthDesignTokens.horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ديل ون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AuthDesignTokens.headingOf(context),
                        ),
                      ),
                      TextButton(
                        key: const Key('onboarding_skip_button'),
                        onPressed:
                            state.isSubmitting ? null : _handleSkipToAuth,
                        child: Text(
                          'تخطي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AuthDesignTokens.mutedOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const Key('onboarding_pageview'),
                      controller: _pageController,
                      itemCount: slides.length,
                      onPageChanged: (index) {
                        ref
                            .read(onboardingControllerProvider.notifier)
                            .setPage(index);
                      },
                      itemBuilder: (context, index) {
                        final slide = slides[index];
                        return _OnboardingSlideView(slide: slide);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OnboardingBottomControls(
                    currentPage: state.currentPage,
                    totalPages: slides.length,
                    primaryLabel: activeSlide.primaryButtonLabel,
                    isSubmitting: state.isSubmitting,
                    onPrimaryPressed: _handleNextOrStart,
                    onBrowseAsGuest: _handleBrowseAsGuest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  final OnboardingSlideData slide;

  const _OnboardingSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnboardingIllustration(slide: slide),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AuthDesignTokens.actionBlueTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        slide.accentIcon,
                        size: 16,
                        color: AuthDesignTokens.actionBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        slide.badgeText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AuthDesignTokens.actionBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AuthDesignTokens.headingOf(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AuthDesignTokens.bodyOf(context),
                    height: 1.6,
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
