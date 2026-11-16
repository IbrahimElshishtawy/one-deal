import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/app/app_router.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/app_page_transitions.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/features/auth/presentation/pages/legal/legal_document_page.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';

import '../../features/auth/auth_controllers_test.dart';

void main() {
  testWidgets(
    'AppRouter builds CustomTransitionPage with cinematic transitions across routes',
    (tester) async {
      final prefs = InMemoryPreferencesService();
      final secureStorage = InMemorySecureStorageService();
      final tokens = InMemoryTokenProvider();
      final repo = FakeAuthRepository(tokens);
      final router = AppRouter.createRouter(initialLocation: RouteNames.login);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(secureStorage),
            tokenProvider.overrideWithValue(tokens),
            authRepositoryProvider.overrideWithValue(repo),
            otpAutoTimerEnabledProvider.overrideWithValue(false),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أهلاً بك مجدداً'), findsOneWidget);

      // Transition to SignUp via cinematic glide
      router.go(RouteNames.signUp);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('أنشئ حسابك في Deal One'), findsOneWidget);

      // Transition to Terms via cinematic vertical lift
      router.push(RouteNames.terms);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('أنشئ حسابك في Deal One'), findsOneWidget);
    },
  );

  testWidgets(
    'AppPageTransitions respects reduced motion accessibility setting',
    (tester) async {
      final router = AppRouter.createRouter(initialLocation: RouteNames.terms);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(
            locale: const Locale('ar'),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.privacy);
      await tester.pump();
      await tester.pump();

      final pageElement = tester.element(find.byType(LegalDocumentPage));
      final route = ModalRoute.of(pageElement);
      expect(route, isNotNull);
      expect(route!.settings, isA<CustomTransitionPage<dynamic>>());
      final customPage = route.settings as CustomTransitionPage<dynamic>;
      expect(customPage.transitionDuration, Duration.zero);
      expect(customPage.reverseTransitionDuration, Duration.zero);
      expect(CinematicTransitionStyle.values.length, 3);
    },
  );
}
