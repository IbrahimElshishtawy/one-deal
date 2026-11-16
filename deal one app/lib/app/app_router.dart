import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_page_transitions.dart';
import '../core/routing/route_guards.dart';
import '../core/routing/route_names.dart';
import '../features/accounts/presentation/screens/profile_screen.dart';
import '../features/auth/domain/entities/auth_session.dart';
import '../features/auth/presentation/pages/legal/legal_document_page.dart';
import '../features/auth/presentation/pages/login/login_page.dart';
import '../features/auth/presentation/pages/onboarding/onboarding_page.dart';
import '../features/auth/presentation/pages/otp_verification/otp_verification_page.dart';
import '../features/auth/presentation/pages/sign_up/sign_up_page.dart';
import '../features/auth/presentation/pages/verification_success/verification_success_page.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/listings/presentation/screens/home_feed_screen.dart';
import '../features/listings/presentation/screens/listing_detail_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';

class AppRouter {
  static GoRouter createRouter({
    RouteGuard? routeGuard,
    Listenable? refreshListenable,
    String initialLocation = RouteNames.root,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: refreshListenable,
      redirect: routeGuard == null
          ? null
          : (context, state) =>
                routeGuard.evaluateRedirect(context, state.uri.toString()),
      routes: [
        GoRoute(
          path: RouteNames.root,
          name: RouteNames.rootName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.reveal,
                child: const HomeFeedScreen(),
              ),
        ),
        GoRoute(
          path: RouteNames.search,
          name: RouteNames.searchName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const SearchScreen(),
              ),
        ),
        GoRoute(
          path: RouteNames.listingDetail,
          name: RouteNames.listingDetailName,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              child: ListingDetailScreen(listingId: id),
            );
          },
        ),
        GoRoute(
          path: RouteNames.favorites,
          name: RouteNames.favoritesName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const FavoritesScreen(),
              ),
        ),
        GoRoute(
          path: RouteNames.profile,
          name: RouteNames.profileName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const ProfileScreen(),
              ),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          name: RouteNames.onboardingName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.reveal,
                child: const OnboardingPage(),
              ),
        ),
        GoRoute(
          path: RouteNames.signUp,
          name: RouteNames.signUpName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: SignUpPage(
                  redirectTo: state.uri.queryParameters['redirect'],
                ),
              ),
        ),
        GoRoute(
          path: RouteNames.login,
          name: RouteNames.loginName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: LoginPage(
                  redirectTo: state.uri.queryParameters['redirect'],
                ),
              ),
        ),
        GoRoute(
          path: RouteNames.otpVerification,
          name: RouteNames.otpVerificationName,
          pageBuilder: (context, state) {
            final extra = state.extra;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              child: OtpVerificationPage(
                authContext: extra is PendingAuthContext ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.verificationSuccess,
          name: RouteNames.verificationSuccessName,
          pageBuilder: (context, state) {
            final extra = state.extra;
            final page = extra is VerificationSuccessArgs
                ? VerificationSuccessPage(
                    session: extra.session,
                    redirectTo: extra.redirectTo,
                  )
                : VerificationSuccessPage(
                    session: extra is AuthSession ? extra : null,
                  );
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.reveal,
              child: page,
            );
          },
        ),
        GoRoute(
          path: RouteNames.terms,
          name: RouteNames.termsName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.verticalLift,
                child: const LegalDocumentPage(
                  documentType: LegalDocumentType.termsOfService,
                ),
              ),
        ),
        GoRoute(
          path: RouteNames.privacy,
          name: RouteNames.privacyName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.verticalLift,
                child: const LegalDocumentPage(
                  documentType: LegalDocumentType.privacyPolicy,
                ),
              ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('الصفحة غير موجودة')),
        body: Center(child: Text('404 - المسار غير موجود: ${state.uri}')),
      ),
    );
  }
}
