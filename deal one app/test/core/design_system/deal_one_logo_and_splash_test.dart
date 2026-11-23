import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/app/splash_screen.dart';
import 'package:market_space/core/constants/app_constants.dart';
import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/core/navigation/drawer/widgets/drawer_footer_widget.dart';

void main() {
  group('DealOne Branding & Logo', () {
    test('AppConstants exposes DealOne app name and exact logo path', () {
      expect(AppConstants.appName, 'DealOne');
      expect(AppConstants.logoAssetPath, 'assets/image/logo.png');
    });

    testWidgets('DealOneLogo renders assets/image/logo.png with BoxFit.contain', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: DealOneLogo(height: 96)),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      expect(image.image, isA<AssetImage>());
      expect(
        (image.image as AssetImage).assetName,
        'assets/image/logo.png',
      );
    });

    testWidgets('SplashScreen displays DealOne logo and navigates to nextRoute', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, _) => const SplashScreen(
              nextRoute: '/home',
              delay: Duration(milliseconds: 100),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home Target')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.byKey(const Key('splash_brand_logo')), findsOneWidget);
      expect(find.text('DealOne'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Home Target'), findsOneWidget);
    });

    testWidgets('DrawerFooterWidget displays DealOneLogo and DealOne branding', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawerFooterWidget(
              isAuthenticated: false,
              isArabic: false,
              onLogout: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('drawer_footer_brand_logo')), findsOneWidget);
      expect(find.text('DealOne — Unified Marketplace'), findsOneWidget);
    });
  });
}
