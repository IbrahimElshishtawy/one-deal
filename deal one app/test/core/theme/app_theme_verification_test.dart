import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/accounts/presentation/screens/profile_screen.dart';
import 'package:market_space/features/auth/presentation/pages/login/login_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/pages/verification_success/verification_success_page.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/bottom_sheets/email_fallback_sheet.dart';
import 'package:market_space/features/auth/presentation/widgets/bottom_sheets/support_contact_sheet.dart';
import 'package:market_space/features/auth/presentation/widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart';
import 'package:market_space/features/auth/presentation/widgets/dialogs/unavailable_provider_dialog.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/shared/models/home_feed_models.dart';
import 'package:market_space/shared/models/market_sector.dart';
import 'package:market_space/shared/widgets/app_empty_state.dart';
import 'package:market_space/shared/widgets/app_error_view.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';
import 'package:market_space/shared/widgets/market_widgets/contractor_promo_banner.dart';
import 'package:market_space/shared/widgets/market_widgets/market_bottom_nav_bar.dart';
import 'package:market_space/shared/widgets/market_widgets/market_category_grid.dart';
import 'package:market_space/shared/widgets/market_widgets/market_header_bar.dart';
import 'package:market_space/shared/widgets/market_widgets/market_search_bar.dart';
import 'package:market_space/shared/widgets/market_widgets/market_section_header.dart';
import 'package:market_space/shared/widgets/market_widgets/market_sector_filter_bar.dart';
import 'package:market_space/shared/widgets/market_widgets/material_product_card.dart';
import 'package:market_space/shared/widgets/market_widgets/real_estate_card.dart';
import 'package:market_space/shared/widgets/market_widgets/service_provider_card.dart';
import 'package:market_space/shared/widgets/market_widgets/trust_guarantee_card.dart';

import '../../features/auth/auth_controllers_test.dart';

void main() {
  testWidgets(
    'AppThemeData resolves Light & Dark tokens, FilterChip, SegmentedButton, and SystemUiOverlayStyle correctly',
    (tester) async {
      final light = AppThemeData.lightTheme;
      final dark = AppThemeData.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppColors.background);
      expect(light.appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.dark);
      expect(light.textSelectionTheme.cursorColor, AppColors.primary);
      expect(
        (light.chipTheme.labelStyle! as WidgetStateTextStyle)
            .resolve(<WidgetState>{})
            .color,
        AppColors.textPrimary,
      );
      expect(
        (light.chipTheme.labelStyle! as WidgetStateTextStyle).resolve({
          WidgetState.selected,
        }).color,
        Colors.white,
      );

      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.appBarTheme.systemOverlayStyle, SystemUiOverlayStyle.light);
      expect(dark.textSelectionTheme.cursorColor, AppColors.darkPrimary);
      expect(
        (dark.chipTheme.labelStyle! as WidgetStateTextStyle).resolve({
          WidgetState.selected,
        }).color,
        AppColors.darkOnPrimary,
      );
      expect(
        (dark.chipTheme.labelStyle! as WidgetStateTextStyle)
            .resolve(<WidgetState>{})
            .color,
        AppColors.darkTextPrimary,
      );
      expect(dark.chipTheme.checkmarkColor, AppColors.darkOnPrimary);

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          theme: light,
          darkTheme: dark,
          home: Scaffold(
            body: Column(
              children: [
                FilterChip(
                  label: const Text('عقارات'),
                  selected: true,
                  onSelected: (_) {},
                ),
                const AppEmptyState(
                  title: 'لا توجد نتائج',
                  message: 'جرب لاحقاً',
                ),
                const AppErrorView(message: 'حدث خطأ'),
                const AppLoadingIndicator(message: 'جاري التحميل'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final msgText = tester.widget<Text>(find.text('جرب لاحقاً'));
      expect(msgText.style?.color, AppColors.darkTextSecondary);
      final errText = tester.widget<Text>(find.text('حدث خطأ'));
      expect(errText.style?.color, AppColors.darkTextSecondary);
      final loadingText = tester.widget<Text>(find.text('جاري التحميل'));
      expect(loadingText.style?.color, AppColors.darkTextSecondary);
    },
  );

  testWidgets(
    'ThemeMode.system reacts dynamically to platformBrightness changes across Auth and Profile',
    (tester) async {
      final prefs = InMemoryPreferencesService();
      final secureStorage = InMemorySecureStorageService();
      final tokens = InMemoryTokenProvider();
      final repo = FakeAuthRepository(tokens);

      addTearDown(() {
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });

      Widget buildApp(String initialLocation) {
        final router = GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(path: '/signup', builder: (_, _) => const SignUpPage()),
            GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
            GoRoute(
              path: '/success',
              builder: (_, _) => const VerificationSuccessPage(),
            ),
            GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          ],
        );
        return ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(secureStorage),
            tokenProvider.overrideWithValue(tokens),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(appThemeModeProvider);
              return MaterialApp.router(
                locale: const Locale('ar'),
                themeMode: mode,
                theme: AppThemeData.lightTheme,
                darkTheme: AppThemeData.darkTheme,
                routerConfig: router,
              );
            },
          ),
        );
      }

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(buildApp('/signup'));
      await tester.pumpAndSettle();
      final lightCtx = tester.element(find.byType(SignUpPage));
      expect(Theme.of(lightCtx).brightness, Brightness.light);
      expect(
        AuthDesignTokens.backgroundOf(lightCtx),
        AuthDesignTokens.lightBackground,
      );
      expect(
        AuthDesignTokens.headingOf(lightCtx),
        AuthDesignTokens.lightTextPrimary,
      );

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      final darkCtx = tester.element(find.byType(SignUpPage));
      expect(Theme.of(darkCtx).brightness, Brightness.dark);
      expect(
        AuthDesignTokens.backgroundOf(darkCtx),
        AuthDesignTokens.darkBackground,
      );
      expect(
        AuthDesignTokens.headingOf(darkCtx),
        AuthDesignTokens.darkTextPrimary,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildApp('/login'));
      await tester.pumpAndSettle();
      expect(find.text('أهلاً بك مجدداً'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildApp('/success'));
      await tester.pumpAndSettle();
      expect(find.text('تم التحقق بنجاح!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildApp('/profile'));
      await tester.pumpAndSettle();
      expect(find.text('مظهر التطبيق'), findsOneWidget);
    },
  );

  testWidgets(
    'All Auth overlays and Market Home widgets adapt text and surface colors in Light and Dark themes',
    (tester) async {
      const realEstate = RealEstateItem(
        id: '1',
        title: 'شقة فاخرة',
        price: '3,500,000 ج.م',
        priceSuffix: 'كاش',
        type: 'للبيع',
        beds: 3,
        baths: 2,
        areaM2: 180,
        location: 'التجمع الخامس',
        timeAgo: 'منذ ساعتين',
        imageUrl: '',
      );
      const material = BuildingMaterialItem(
        id: 'm1',
        title: 'أسمنت السويس',
        subtitle: 'توريد مباشر',
        price: '2,400 ج.م',
        unit: 'طن',
        tag: 'جملة',
        footerText: 'توصيل فوري',
        imageUrl: '',
      );
      const provider = ServiceProviderItem(
        id: 's1',
        name: 'شركة النيل للتشطيبات',
        serviceDesc: 'تشطيب متكامل',
        rating: 4.9,
        reviewsCount: 42,
        perkText: 'ضمان سنتين',
        actionLabel: 'اطلب عرض',
        categoryKey: 'finishing',
      );

      Future<void> pumpShowcase(ThemeMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            themeMode: mode,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            home: Scaffold(
              bottomNavigationBar: const MarketBottomNavBar(currentIndex: 0),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const MarketHeaderBar(selectedCity: 'القاهرة'),
                    const MarketSearchBar(),
                    MarketSectorFilterBar(
                      activeSector: MarketSector.all,
                      onSectorChanged: (_) {},
                    ),
                    const MarketCategoryGrid(),
                    const ContractorPromoBanner(),
                    const MarketSectionHeader(
                      title: 'عقارات مميزة',
                      markerColor: AppColors.secondary,
                    ),
                    const RealEstateCard(item: realEstate),
                    const MaterialProductCard(item: material),
                    const ServiceProviderCard(item: provider),
                    const TrustGuaranteeCard(),
                    WhatsAppDeliveryFailureSheet(
                      displayPhone: '+20 101 234 5678',
                      onEditPhone: () {},
                      onSendViaSms: () {},
                      onTryEmail: () {},
                      onContactSupport: () {},
                    ),
                    const EmailFallbackSheet(),
                    const SupportContactSheet(),
                    const UnavailableProviderDialog(
                      provider: SocialAuthProviderType.google,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpShowcase(ThemeMode.light);
      expect(
        tester.widget<Text>(find.text('شقة فاخرة')).style?.color,
        AppColors.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('أسمنت السويس')).style?.color,
        AppColors.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('شركة النيل للتشطيبات')).style?.color,
        AppColors.textPrimary,
      );
      expect(
        tester
            .widget<Text>(find.text('حماية المعاملات 100% عبر بازار جو'))
            .style
            ?.color,
        AppColors.textPrimary,
      );

      await pumpShowcase(ThemeMode.dark);
      expect(
        tester.widget<Text>(find.text('شقة فاخرة')).style?.color,
        AppColors.darkTextPrimary,
      );
      expect(
        tester.widget<Text>(find.text('أسمنت السويس')).style?.color,
        AppColors.darkTextPrimary,
      );
      expect(
        tester.widget<Text>(find.text('شركة النيل للتشطيبات')).style?.color,
        AppColors.darkTextPrimary,
      );
      expect(
        tester
            .widget<Text>(find.text('حماية المعاملات 100% عبر بازار جو'))
            .style
            ?.color,
        AppColors.darkTextPrimary,
      );
    },
  );
}
