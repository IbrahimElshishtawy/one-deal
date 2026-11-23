import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/navigation/presentation/widgets/deal_one_navigation_shell.dart';
import 'package:market_space/core/routing/app_page_transitions.dart';
import 'package:market_space/core/routing/route_guards.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/accounts/presentation/screens/edit_account_page.dart';
import 'package:market_space/features/accounts/presentation/screens/profile_screen.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/presentation/pages/activity_hub_page.dart';
import 'package:market_space/features/appliances_decor/presentation/pages/appliances_decor_home_page.dart';
import 'package:market_space/features/auth/domain/entities/auth_session.dart';
import 'package:market_space/features/auth/presentation/pages/legal/legal_document_page.dart';
import 'package:market_space/features/auth/presentation/pages/login/login_page.dart';
import 'package:market_space/features/auth/presentation/pages/onboarding/onboarding_page.dart';
import 'package:market_space/features/auth/presentation/pages/otp_verification/otp_verification_page.dart';
import 'package:market_space/features/auth/presentation/pages/sign_up/sign_up_page.dart';
import 'package:market_space/features/auth/presentation/pages/verification_success/verification_success_page.dart';
import 'package:market_space/features/cars_maintenance/presentation/pages/cars_maintenance_home_page.dart';
import 'package:market_space/features/categories/presentation/screens/section_categories_page.dart';
import 'package:market_space/features/construction_electrical/presentation/pages/construction_electrical_home_page.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';
import 'package:market_space/features/conversations/presentation/pages/conversation_chat_page.dart';
import 'package:market_space/features/conversations/presentation/pages/conversations_page.dart';
import 'package:market_space/features/fashion_accessories/presentation/pages/fashion_accessories_home_page.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/screens/create_listing_page.dart';
import 'package:market_space/features/listings/presentation/screens/listing_detail_screen.dart';
import 'package:market_space/features/listings/presentation/screens/seller_management_page.dart';
import 'package:market_space/features/main_hub/presentation/pages/main_hub_page.dart';
import 'package:market_space/features/maps/presentation/pages/category_map_page.dart';
import 'package:market_space/features/notifications/presentation/pages/notifications_page.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';
import 'package:market_space/features/real_estate/presentation/pages/photo_gallery_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_details_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_home_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_map_page.dart';
import 'package:market_space/features/real_estate/presentation/pages/real_estate_reels_page.dart';
import 'package:market_space/features/search/presentation/screens/search_screen.dart';
import 'package:market_space/features/services_engineering/presentation/pages/services_engineering_home_page.dart';

class AppRouter {
  static GoRouter createRouter({
    RouteGuard? routeGuard,
    Listenable? refreshListenable,
    String initialLocation = RouteNames.root,
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: refreshListenable,
      redirect: routeGuard == null
          ? null
          : (context, state) =>
                routeGuard.evaluateRedirect(context, state.uri.toString()),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              DealOneNavigationShell(navigationShell: navigationShell),
          branches: [
            // Branch 0: Home (الرئيسية)
            StatefulShellBranch(
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
              ],
            ),
            // Branch 1: Favorites (المفضلة)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.favorites,
                  name: RouteNames.favoritesName,
                  pageBuilder: (context, state) =>
                      AppPageTransitions.buildCinematicPage(
                        context: context,
                        state: state,
                        child: const ActivityHubPage(
                          key: ValueKey<String>('shell_favorites_tab'),
                          initialTab: ActivityHubTab.favorites,
                        ),
                      ),
                ),
              ],
            ),
            // Branch 2: Orders (طلباتي)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.activityHub,
                  name: RouteNames.activityHubName,
                  pageBuilder: (context, state) {
                    final tab = ActivityHubTab.fromQuery(
                      state.uri.queryParameters['tab'],
                    );
                    final categorySlug = state.uri.queryParameters['category'];
                    return AppPageTransitions.buildCinematicPage(
                      context: context,
                      state: state,
                      child: ActivityHubPage(
                        key: const ValueKey<String>('shell_orders_tab'),
                        initialTab: tab,
                        initialCategorySlug: categorySlug,
                      ),
                    );
                  },
                ),
              ],
            ),
            // Branch 3: Profile (البروفايل)
            StatefulShellBranch(
              routes: [
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
              ],
            ),
          ],
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
          path: RouteNames.editAccount,
          name: RouteNames.editAccountName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.glide,
                child: const EditAccountPage(),
              ),
        ),
        GoRoute(
          path: RouteNames.conversations,
          name: RouteNames.conversationsName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.glide,
                child: const ConversationsPage(),
              ),
        ),
        GoRoute(
          path: RouteNames.conversationChat,
          name: RouteNames.conversationChatName,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.glide,
              child: ConversationChatPage(
                conversationId: id,
                initialConversation: extra is ConversationEntity ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.globalNotifications,
          name: RouteNames.globalNotificationsName,
          pageBuilder: (context, state) =>
              AppPageTransitions.buildCinematicPage(
                context: context,
                state: state,
                style: CinematicTransitionStyle.verticalLift,
                child: const NotificationsPage(),
              ),
        ),
        GoRoute(
          path: RouteNames.realEstateMap,
          name: RouteNames.realEstateMapName,
          pageBuilder: (context, state) {
            final extra = state.extra;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.verticalLift,
              child: RealEstateMapPage(
                focusedProperty: extra is ListingItem ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.categoryMap,
          name: RouteNames.categoryMapName,
          pageBuilder: (context, state) {
            final slug = state.pathParameters['categorySlug'] ?? 'real-estate';
            final extra = state.extra;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.reveal,
              child: CategoryMapPage(
                categorySlug: slug,
                focusedListing: extra is ListingItem ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.sectionCategories,
          name: RouteNames.sectionCategoriesName,
          pageBuilder: (context, state) {
            final slug =
                state.pathParameters['categorySlug'] ?? 'building-materials';
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.glide,
              child: SectionCategoriesPage(categorySlug: slug),
            );
          },
        ),
        GoRoute(
          path: RouteNames.sellerManagement,
          name: RouteNames.sellerManagementName,
          pageBuilder: (context, state) {
            final slug = state.pathParameters['categorySlug'] ?? 'real-estate';
            final mode = state.pathParameters['mode'] ?? 'listings';
            final tabParam = state.uri.queryParameters['tab'];
            final initialTabIndex = tabParam == 'incoming' ? 1 : 0;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.glide,
              child: SellerManagementPage(
                categorySlug: slug,
                mode: mode,
                initialTabIndex: initialTabIndex,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.createListing,
          name: RouteNames.createListingName,
          pageBuilder: (context, state) {
            final slug =
                state.uri.queryParameters['category'] ?? 'real-estate';
            final kind = state.uri.queryParameters['kind'] ?? 'sale';
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.verticalLift,
              child: CreateListingPage(
                categorySlug: slug,
                listingKind: kind,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.realEstateGallery,
          name: RouteNames.realEstateGalleryName,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra;
            final args = extra is PhotoGalleryArgs ? extra : null;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.reveal,
              child: PhotoGalleryPage(
                listingId: id,
                initialListing: args?.listing,
                initialIndex: args?.initialIndex ?? 0,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.realEstateReels,
          name: RouteNames.realEstateReelsName,
          pageBuilder: (context, state) {
            final extra = state.extra;
            final initialIdx =
                int.tryParse(state.uri.queryParameters['index'] ?? '') ?? 0;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.reveal,
              child: RealEstateReelsPage(
                initialIndex: initialIdx,
                initialItems: extra is List<ReelItemEntity> ? extra : null,
              ),
            );
          },
        ),
        GoRoute(
          path: RouteNames.realEstateDetail,
          name: RouteNames.realEstateDetailName,
          pageBuilder: (context, state) {
            final id = state.uri.queryParameters['id'] ?? '';
            final extra = state.extra;
            return AppPageTransitions.buildCinematicPage(
              context: context,
              state: state,
              style: CinematicTransitionStyle.glide,
              child: RealEstateDetailsPage(
                listingId: id,
                preloadedItem: extra is ListingItem ? extra : null,
              ),
            );
          },
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
