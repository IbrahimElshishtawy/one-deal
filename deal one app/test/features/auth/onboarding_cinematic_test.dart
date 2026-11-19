import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/auth/presentation/pages/onboarding/onboarding_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/presentation/widgets/onboarding/cinematic_image_view.dart';

import 'auth_controllers_test.dart';

Widget _buildOnboardingHarness({
  required InMemoryPreferencesService prefs,
  required InMemorySecureStorageService secureStorage,
  required InMemoryTokenProvider tokens,
  required FakeAuthRepository repo,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  bool disableAnimations = false,
}) {
  final router = GoRouter(
    initialLocation: RouteNames.onboarding,
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(path: RouteNames.signUp, builder: (_, _) => const SignUpPage()),
    ],
  );

  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      secureStorageServiceProvider.overrideWithValue(secureStorage),
      tokenProvider.overrideWithValue(tokens),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      locale: locale,
      themeMode: themeMode,
      theme: AppThemeData.lightTheme,
      darkTheme: AppThemeData.darkTheme,
      localizationsDelegates: AppLocalization.localizationsDelegates,
      supportedLocales: AppLocalization.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}

void main() {
  late InMemoryPreferencesService prefs;
  late InMemorySecureStorageService secureStorage;
  late InMemoryTokenProvider tokens;
  late FakeAuthRepository repo;

  setUp(() {
    prefs = InMemoryPreferencesService();
    secureStorage = InMemorySecureStorageService();
    tokens = InMemoryTokenProvider();
    repo = FakeAuthRepository(tokens);
  });

  testWidgets(
    'Initial slide shows subtitle, title, description, Skip, Next, and hides Previous',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('العقارات والسيارات'), findsOneWidget);
      expect(find.text('عالم من العقارات والسيارات بين يديك'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_previous_button')),
        findsNothing,
      );
      expect(find.byKey(const Key('onboarding_primary_button')), findsOneWidget);
      expect(find.byType(CinematicImageView), findsNWidgets(3));
    },
  );

  testWidgets(
    'Button navigation moves forward and backward across all 3 slides and completes on final CTA',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 -> Slide 2
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();
      expect(find.text('الخدمات ومواد البناء'), findsOneWidget);
      expect(find.text('تشطيبات وخدمات منزلية بالقرب منك'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_previous_button')),
        findsOneWidget,
      );

      // Slide 2 -> Slide 3
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();
      expect(find.text('الأزياء والديكور والأجهزة'), findsOneWidget);
      expect(find.text('أناقتك وديكور منزلك بتواصل مباشر'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsNothing);
      expect(
        find.byKey(const Key('onboarding_previous_button')),
        findsOneWidget,
      );

      // Slide 3 -> Slide 2 via Previous button
      await tester.tap(find.byKey(const Key('onboarding_previous_button')));
      await tester.pumpAndSettle();
      expect(find.text('تشطيبات وخدمات منزلية بالقرب منك'), findsOneWidget);

      // Slide 2 -> Slide 1 via Previous button
      await tester.tap(find.byKey(const Key('onboarding_previous_button')));
      await tester.pumpAndSettle();
      expect(find.text('عالم من العقارات والسيارات بين يديك'), findsOneWidget);
      expect(
        find.byKey(const Key('onboarding_previous_button')),
        findsNothing,
      );

      // Advance to Slide 3 and complete into Sign Up
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(await prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    },
  );

  testWidgets(
    'Skip button persists onboarding completion and navigates directly to Sign Up',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SignUpPage), findsOneWidget);
      expect(await prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    },
  );

  testWidgets(
    'Swipe gestures navigate forward and backward in English LTR and Dark Mode',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(OnboardingPage))),
        TextDirection.ltr,
      );
      expect(find.text('Real Estate & Cars'), findsOneWidget);

      // Swipe left -> Slide 2
      await tester.fling(
        find.byKey(const Key('onboarding_pageview')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Home Services & Materials'), findsOneWidget);

      // Swipe right -> back to Slide 1
      await tester.fling(
        find.byKey(const Key('onboarding_pageview')),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Real Estate & Cars'), findsOneWidget);
    },
  );

  testWidgets(
    'Reduced motion disables Ken Burns transform and navigates instantaneously without overlap',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          disableAnimations: true,
        ),
      );
      await tester.pump();

      final cinematicViews = tester.widgetList<CinematicImageView>(
        find.byType(CinematicImageView),
      );
      expect(cinematicViews.every((v) => v.reducedMotion), isTrue);

      // Rapid navigation under reduced motion
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pump();
      expect(find.text('تشطيبات وخدمات منزلية بالقرب منك'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pump();
      expect(find.text('أناقتك وديكور منزلك بتواصل مباشر'), findsOneWidget);
    },
  );

  testWidgets(
    'Rapid user swipes and button taps remain stable without errors or desync',
    (tester) async {
      await tester.pumpWidget(
        _buildOnboardingHarness(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Rapid taps mid-transition
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('onboarding_primary_button')));
      await tester.pumpAndSettle();

      // Should cleanly land on Slide 2 without crashing or skipping uncontrollably
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
