import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/providers/app_settings_providers.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_theme_data.dart';
import 'package:market_space/features/accounts/presentation/screens/profile_screen.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/presentation/pages/legal/legal_document_page.dart';
import 'package:market_space/features/auth/presentation/pages/login/login_page.dart';
import 'package:market_space/features/auth/presentation/pages/onboarding/onboarding_page.dart';
import 'package:market_space/features/auth/presentation/pages/otp_verification/otp_verification_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/pages/verification_success/verification_success_page.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_error_banner.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_legal_footer.dart';
import 'package:market_space/features/auth/presentation/widgets/otp/otp_pin_boxes.dart';
import 'package:market_space/shared/widgets/market_widgets/market_header_bar.dart';
import 'package:market_space/shared/widgets/market_widgets/market_search_bar.dart';

import 'auth_controllers_test.dart';

Widget _buildRoutedApp({
  required InMemoryPreferencesService prefs,
  required InMemorySecureStorageService secureStorage,
  required InMemoryTokenProvider tokens,
  required FakeAuthRepository repo,
  String initialLocation = RouteNames.onboarding,
  Object? initialExtra,
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      GoRoute(
        path: RouteNames.root,
        builder: (_, _) => const Scaffold(body: Text('HOME_ROOT')),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(path: RouteNames.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(path: RouteNames.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: RouteNames.otpVerification,
        builder: (_, state) => OtpVerificationPage(
          authContext: state.extra is PendingAuthContext
              ? state.extra as PendingAuthContext
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.verificationSuccess,
        builder: (_, state) {
          final extra = state.extra;
          if (extra is VerificationSuccessArgs) {
            return VerificationSuccessPage(
              session: extra.session,
              redirectTo: extra.redirectTo,
            );
          }
          return VerificationSuccessPage(
            session: extra is AuthSession ? extra : null,
          );
        },
      ),
      GoRoute(
        path: RouteNames.terms,
        builder: (_, _) => const LegalDocumentPage(
          documentType: LegalDocumentType.termsOfService,
        ),
      ),
      GoRoute(
        path: RouteNames.privacy,
        builder: (_, _) => const LegalDocumentPage(
          documentType: LegalDocumentType.privacyPolicy,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      preferencesServiceProvider.overrideWithValue(prefs),
      secureStorageServiceProvider.overrideWithValue(secureStorage),
      tokenProvider.overrideWithValue(tokens),
      authRepositoryProvider.overrideWithValue(repo),
      otpAutoTimerEnabledProvider.overrideWithValue(false),
    ],
    child: MaterialApp.router(
      locale: locale,
      themeMode: themeMode,
      theme: AppThemeData.lightTheme,
      darkTheme: AppThemeData.darkTheme,
      localizationsDelegates: AppLocalization.localizationsDelegates,
      supportedLocales: AppLocalization.supportedLocales,
      routerConfig: router,
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
    'Onboarding progresses through 3 screens and completes into Sign Up',
    (tester) async {
      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.onboarding,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('عالم من العقارات والسيارات بين يديك'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('تشطيبات وخدمات منزلية بالقرب منك'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('أناقتك وديكور منزلك بتواصل مباشر'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsNothing);

      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();

      expect(find.text('أنشئ حسابك في Deal One'), findsOneWidget);
      expect(await prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    },
  );

  testWidgets(
    'Sign Up validates inputs, opens Email/Apple notice dialog, and navigates to Login',
    (tester) async {
      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.signUp,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text('من فضلك أدخل الاسم الكامل'), findsOneWidget);
      expect(find.text('من فضلك أدخل رقم الهاتف'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('social_email_button')));
      await tester.tap(find.byKey(const Key('social_email_button')));
      await tester.pumpAndSettle();
      expect(
        find.text('التسجيل عبر البريد الإلكتروني غير مفعل حالياً'),
        findsOneWidget,
      );
      await tester.tap(find.text('فهمت، المتابعة برقم الهاتف'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('signup_to_login_button')),
      );
      await tester.tap(find.byKey(const Key('signup_to_login_button')));
      await tester.pumpAndSettle();
      expect(find.text('أهلاً بك مجدداً'), findsOneWidget);
    },
  );

  testWidgets(
    'Login triggers WhatsApp delivery failure sheet automatically on backend delivery failure',
    (tester) async {
      repo.nextSendError = const ServerException(
        message: 'WhatsApp number not registered',
        errorCode: 'WHATSAPP_UNAVAILABLE',
      );

      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.login,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('login_phone_field')),
          matching: find.byType(TextField),
        ),
        '01012345678',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('تعذر الإرسال عبر واتساب'), findsOneWidget);
      expect(find.text('+20 101 234 5678'), findsOneWidget);
      expect(find.byKey(const Key('sheet_try_email_button')), findsOneWidget);
      expect(find.byKey(const Key('sheet_send_sms_button')), findsOneWidget);
      expect(find.byKey(const Key('sheet_edit_phone_button')), findsOneWidget);
    },
  );

  testWidgets(
    'Login dispatches OTP, shows LTR 6-digit OTP boxes, invalid state with retry, WhatsApp failure sheet, and success screen',
    (tester) async {
      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.login,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('login_phone_field')),
          matching: find.byType(TextField),
        ),
        '01012345678',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('أدخل رمز التحقق'), findsOneWidget);
      expect(find.textContaining('+20 101 234 5678'), findsOneWidget);

      // Verify 6-digit pin boxes exist and run inside LTR Directionality
      final pinBoxesFinder = find.byType(OtpPinBoxes);
      expect(pinBoxesFinder, findsOneWidget);
      final dirWidget = tester.widget<Directionality>(
        find
            .descendant(
              of: pinBoxesFinder,
              matching: find.byType(Directionality),
            )
            .first,
      );
      expect(dirWidget.textDirection, TextDirection.ltr);

      // WhatsApp failure bottom sheet & Email fallback sheet
      await tester.ensureVisible(
        find.byKey(const Key('otp_delivery_help_button')),
      );
      await tester.tap(find.byKey(const Key('otp_delivery_help_button')));
      await tester.pumpAndSettle();
      expect(find.text('تعذر الإرسال عبر واتساب'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('sheet_try_email_button')),
      );
      await tester.tap(find.byKey(const Key('sheet_try_email_button')));
      await tester.pumpAndSettle();
      expect(find.text('التحقق بالبريد الإلكتروني'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('email_fallback_field')),
          matching: find.byType(TextField),
        ),
        'test@dealone.eg',
      );
      await tester.ensureVisible(
        find.byKey(const Key('email_fallback_submit')),
      );
      await tester.tap(find.byKey(const Key('email_fallback_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_fallback_notice')), findsOneWidget);

      // Close Email sheet cleanly
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Invalid OTP state with remaining attempts pill & retry button
      repo.nextVerifyError = const ValidationException(
        message: 'Incorrect OTP code.',
      );
      await tester.enterText(
        find.byKey(const Key('otp_hidden_input')),
        '000000',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('otp_error_banner')), findsOneWidget);
      expect(
        find.text('رمز التحقق غير صحيح، يرجى التأكد وإعادة المحاولة'),
        findsOneWidget,
      );
      expect(find.textContaining('متبقي لك 4 محاولات'), findsOneWidget);
      expect(find.byKey(const Key('otp_retry_button')), findsOneWidget);

      // Tap retry clears invalid code
      await tester.tap(find.byKey(const Key('otp_retry_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('otp_error_banner')), findsNothing);

      // Valid OTP transitions to Verification Success then Home
      repo.nextVerifyError = null;
      repo.currentUser = const AuthUser(
        id: 'user_1',
        phone: '+201012345678',
        fullName: 'محمود عادل',
        isPhoneVerified: true,
      );
      await tester.enterText(
        find.byKey(const Key('otp_hidden_input')),
        '123456',
      );
      await tester.pumpAndSettle();

      expect(find.text('تم التحقق بنجاح!'), findsOneWidget);
      expect(find.textContaining('محمود عادل'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('verification_success_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('HOME_ROOT'), findsOneWidget);
    },
  );

  testWidgets(
    'OTP expired state displays expiration alert card and unlocks resend CTA',
    (tester) async {
      const contextData = PendingAuthContext(
        normalizedPhone: '+201012345678',
        displayPhone: '+20 101 234 5678',
        pendingFullName: 'سارة علي',
        flowMode: AuthFlowMode.signUp,
        cooldownSeconds: 0,
        otpExpirySeconds: 180,
      );

      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.otpVerification,
          initialExtra: contextData,
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(OtpVerificationPage));
      final container = ProviderScope.containerOf(element);
      container
          .read(otpVerificationControllerProvider(contextData).notifier)
          .advanceSecondsForTest(180);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('otp_expired_card')), findsOneWidget);
      expect(
        find.text('انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
    },
  );

  testWidgets(
    'SignUp subtitle renders cleanly and input focus border is black in light mode',
    (tester) async {
      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.signUp,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ابحث عن عقارك، سيارتك، وصفقاتك في مكان واحد.'),
        findsOneWidget,
      );

      final nameField = find.byKey(const Key('signup_fullname_field'));
      await tester.tap(
        find.descendant(of: nameField, matching: find.byType(TextField)),
      );
      await tester.pumpAndSettle();

      final focusedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: nameField,
          matching: find.byType(AnimatedContainer),
        ),
      );
      final decoration = focusedContainer.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, const Color(0xFF111111));
    },
  );

  testWidgets(
    'Profile theme selector switches System, Dark, and Light themes across the app',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(secureStorage),
            tokenProvider.overrideWithValue(tokens),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(appThemeModeProvider);
              return MaterialApp(
                locale: const Locale('ar'),
                themeMode: themeMode,
                theme: AppThemeData.lightTheme,
                darkTheme: AppThemeData.darkTheme,
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileContext = tester.element(find.byType(ProfileScreen));
      expect(
        ProviderScope.containerOf(profileContext).read(appThemeModeProvider),
        ThemeMode.system,
      );

      await tester.ensureVisible(find.text('داكن'));
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(profileContext).read(appThemeModeProvider),
        ThemeMode.dark,
      );
      expect(Theme.of(profileContext).brightness, Brightness.dark);
      expect(
        AuthDesignTokens.focusBorderOf(profileContext),
        AuthDesignTokens.darkTextPrimary,
      );

      await tester.tap(find.text('فاتح'));
      await tester.pumpAndSettle();
      expect(
        ProviderScope.containerOf(profileContext).read(appThemeModeProvider),
        ThemeMode.light,
      );
      expect(Theme.of(profileContext).brightness, Brightness.light);
    },
  );

  testWidgets(
    'All shared and auth text colors adapt dynamically across Light and Dark themes',
    (tester) async {
      Future<void> pumpHarness(ThemeMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            themeMode: mode,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  const MarketHeaderBar(selectedCity: 'القاهرة'),
                  const MarketSearchBar(),
                  AuthErrorBanner(
                    message: 'خطأ في الإدخال',
                    actionLabel: 'إعادة المحاولة',
                    onActionPressed: () {},
                  ),
                  AuthLegalFooter(onTermsTap: () {}, onPrivacyTap: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpHarness(ThemeMode.light);
      expect(
        tester.widget<Text>(find.text('بازار جو')).style?.color,
        AppColors.textPrimary,
      );
      expect(
        tester.widget<Text>(find.text('خطأ في الإدخال')).style?.color,
        AuthDesignTokens.errorDeepRed,
      );
      expect(
        tester.widget<Text>(find.text('إعادة المحاولة')).style?.color,
        AuthDesignTokens.lightTextPrimary,
      );

      await pumpHarness(ThemeMode.dark);
      expect(
        tester.widget<Text>(find.text('بازار جو')).style?.color,
        AppColors.darkTextPrimary,
      );
      expect(
        tester.widget<Text>(find.text('خطأ في الإدخال')).style?.color,
        const Color(0xFFFCA5A5),
      );
      expect(
        tester.widget<Text>(find.text('إعادة المحاولة')).style?.color,
        AuthDesignTokens.darkTextPrimary,
      );
    },
  );

  testWidgets(
    'English LTR renders Onboarding, Sign Up, Login, OTP, Error states, and Success cleanly in Dark Mode',
    (tester) async {
      await tester.pumpWidget(
        _buildRoutedApp(
          prefs: prefs,
          secureStorage: secureStorage,
          tokens: tokens,
          repo: repo,
          initialLocation: RouteNames.onboarding,
          locale: const Locale('en'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(OnboardingPage))),
        TextDirection.ltr,
      );
      expect(
        find.text('A World of Real Estate & Cars in Your Hands'),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Finishing & Home Services Near You'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Your Style & Home Decor with Direct Contact'),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create your Deal One account'), findsOneWidget);

      // Trigger localized English validation errors
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter your phone number'), findsOneWidget);

      // Navigate to Login and verify English copy + dark theme background
      await tester.ensureVisible(find.byKey(const Key('signup_to_login_button')));
      await tester.tap(find.byKey(const Key('signup_to_login_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);

      // Enter valid Egyptian phone and advance to OTP
      await tester.enterText(
        find.byKey(const Key('login_phone_field')),
        '01012345678',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();
      expect(find.text('Enter Verification Code'), findsOneWidget);

      // Verify invalid OTP state renders English banner + attempts pill
      repo.nextVerifyError = const UnauthorizedException(
        message: 'Incorrect OTP code.',
      );
      await tester.enterText(
        find.byKey(const Key('otp_hidden_input')),
        '000000',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Incorrect verification code, please check and try again'),
        findsOneWidget,
      );

      // Retry with valid code -> Success screen in English
      repo.nextVerifyError = null;
      await tester.tap(find.byKey(const Key('otp_retry_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('otp_hidden_input')),
        '123456',
      );
      await tester.pumpAndSettle();
      expect(find.text('Verified Successfully!'), findsOneWidget);
      expect(find.text('Continue to Login'), findsOneWidget);
    },
  );

  testWidgets(
    'Profile language selector switches Arabic RTL and English LTR live and persists locale',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(secureStorage),
            tokenProvider.overrideWithValue(tokens),
            authRepositoryProvider.overrideWithValue(repo),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(appLocaleProvider);
              return MaterialApp(
                locale: locale,
                theme: AppThemeData.lightTheme,
                darkTheme: AppThemeData.darkTheme,
                localizationsDelegates: AppLocalization.localizationsDelegates,
                supportedLocales: AppLocalization.supportedLocales,
                home: const ProfileScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default Arabic RTL
      expect(find.text('حسابي'), findsOneWidget);
      expect(find.text('لغة التطبيق'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(ProfileScreen))),
        TextDirection.rtl,
      );

      // Switch to English LTR
      await tester.ensureVisible(find.text('English'));
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('App Language'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(ProfileScreen))),
        TextDirection.ltr,
      );
      expect(await prefs.getString(StorageKeys.languageCode), 'en');
    },
  );
}
