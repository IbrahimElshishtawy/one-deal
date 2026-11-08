import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/route_guards.dart';
import '../core/routing/route_names.dart';
import '../features/accounts/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/login_otp_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/listings/presentation/screens/home_feed_screen.dart';
import '../features/listings/presentation/screens/listing_detail_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';

class AppRouter {
  static GoRouter createRouter({
    RouteGuard? routeGuard,
    String initialLocation = RouteNames.root,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: RouteNames.root,
          name: RouteNames.rootName,
          builder: (context, state) => const HomeFeedScreen(),
        ),
        GoRoute(
          path: RouteNames.search,
          name: RouteNames.searchName,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: RouteNames.listingDetail,
          name: RouteNames.listingDetailName,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ListingDetailScreen(listingId: id);
          },
        ),
        GoRoute(
          path: RouteNames.favorites,
          name: RouteNames.favoritesName,
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          name: RouteNames.profileName,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.login,
          name: RouteNames.loginName,
          builder: (context, state) => const LoginOtpScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('الصفحة غير موجودة')),
        body: Center(
          child: Text('404 - المسار غير موجود: ${state.uri}'),
        ),
      ),
    );
  }
}
