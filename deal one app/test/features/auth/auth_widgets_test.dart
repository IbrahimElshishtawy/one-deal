import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/storage/preferences_service.dart';
import 'package:market_space/core/storage/secure_storage_service.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/presentation/pages/legal/legal_document_page.dart';
import 'package:market_space/features/auth/presentation/pages/login/login_page.dart';
import 'package:market_space/features/auth/presentation/pages/onboarding/onboarding_page.dart';
import 'package:market_space/features/auth/presentation/pages/otp_verification/otp_verification_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/pages/verification_success/verification_success_page.dart';
import 'package:market_space/features/auth/presentation/providers/auth_providers.dart';
import 'package:market_space/features/auth/presentation/widgets/otp/otp_pin_boxes.dart';

import 'auth_controllers_test.dart';

Widget _buildRoutedApp({
  required InMemoryPreferencesService prefs,
  required InMemorySecureStorageService secureStorage,
  required InMemoryTokenProvider tokens,
  required FakeAuthRepository repo,
  String initialLocation = RouteNames.onboarding,
  Object? initialExtra,
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
        builder: (_, state) => VerificationSuccessPage(
          session: state.extra is AuthSession
              ? state.extra as AuthSession
              : null,
        ),
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
    child: MaterialApp.router(locale: const Locale('ar'), routerConfig: router),
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

      expect(find.text('كل ما تحتاجه في مكان واحد'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('تواصل مباشر وصفقات آمنة'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('أفضل العروض بالقرب منك'), findsOneWidget);

      await tester.tap(find.text('ابدأ الآن'));
      await tester.pumpAndSettle();

      expect(find.text('إنشاء حساب جديد'), findsOneWidget);
      expect(await prefs.getBool(StorageKeys.onboardingCompleted), isTrue);
    },
  );

  testWidgets(
    'Sign Up validates inputs, navigates to Login, and opens Google provider dialog',
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

      await tester.ensureVisible(find.text('Google'));
      await tester.tap(find.text('Google'));
      await tester.pumpAndSettle();
      expect(find.text('التسجيل عبر Google غير مفعل حالياً'), findsOneWidget);
      await tester.tap(find.text('فهمت، المتابعة برقم الهاتف'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('signup_to_login_button')),
      );
      await tester.tap(find.byKey(const Key('signup_to_login_button')));
      await tester.pumpAndSettle();
      expect(find.text('مرحباً بعودتك'), findsOneWidget);
    },
  );

  testWidgets(
    'Login dispatches OTP, shows LTR 6-digit OTP boxes, invalid/expired states, WhatsApp failure sheet, and success screen',
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
      expect(find.text('+20 101 234 5678'), findsOneWidget);

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
      await tester.ensureVisible(find.byKey(const Key('email_fallback_submit')));
      await tester.tap(find.byKey(const Key('email_fallback_submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_fallback_notice')), findsOneWidget);

      // Close Email sheet cleanly
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Invalid OTP state
      repo.nextVerifyError = const UnauthorizedException(
        message: 'Incorrect OTP code.',
      );
      await tester.enterText(
        find.byKey(const Key('otp_hidden_input')),
        '000000',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('otp_error_banner')), findsOneWidget);
      expect(
        find.text('الرمز غير صحيح، يرجى المحاولة مرة أخرى'),
        findsOneWidget,
      );

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

      expect(find.text('تم التحقق من حسابك بنجاح!'), findsOneWidget);
      expect(find.textContaining('محمود عادل'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('verification_success_continue_button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('HOME_ROOT'), findsOneWidget);
    },
  );

  testWidgets(
    'OTP expired state displays expiration banner and unlocks resend CTA',
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

      expect(
        find.text('انتهت صلاحية الرمز، يرجى طلب رمز جديد'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
    },
  );
}
