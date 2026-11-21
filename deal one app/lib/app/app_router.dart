import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/routing/app_page_transitions.dart';
import 'package:market_space/core/routing/route_guards.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/accounts/presentation/screens/profile_screen.dart';
import 'package:market_space/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/presentation/pages/legal/legal_document_page.dart';
import 'package:market_space/features/auth/presentation/pages/login/login_page.dart';
import 'package:market_space/features/auth/presentation/pages/onboarding/onboarding_page.dart';
import 'package:market_space/features/auth/presentation/pages/otp_verification/otp_verification_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/pages/verification_success/verification_success_page.dart';
import 'package:market_space/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart';
import 'package:market_space/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart';
import 'package:market_space/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart';
import 'package:market_space/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:market_space/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:market_space/features/main_hub/presentation/pages/main_hub_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/search/presentation/screens/search_screen.dart';
import 'package:market_space/features/services_engineering/presentation/pages/services_engineering_home_page.dart';

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
                child: const MainHubPage(),
              ),
        ),
        GoRoute(
          path: RouteNames.realEstate,
          name: RouteNames.realEstateName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const RealEstateHomePage(),
              ),
        ),
        GoRoute(
          path: RouteNames.homeAppliances,
          name: RouteNames.homeAppliancesName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const AppliancesDecorHomePage(),
              ),
        ),
        GoRoute(
          path: RouteNames.homeServices,
          name: RouteNames.homeServicesName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const ServicesEngineeringHomePage(),
              ),
        ),
        GoRoute(
          path: RouteNames.buildingMaterials,
          name: RouteNames.buildingMaterialsName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const ConstructionElectricalHomePage(),
              ),
        ),
        GoRoute(
          path: RouteNames.cars,
          name: RouteNames.carsName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const CarsMaintenanceHomePage(),
              ),
        ),
        GoRoute(
          path: RouteNames.fashion,
          name: RouteNames.fashionName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                child: const FashionAccessoriesHomePage(),
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
