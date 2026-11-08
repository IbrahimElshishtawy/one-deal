import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/route_guards.dart';
import '../core/routing/route_names.dart';
import '../shared/widgets/market_home_screen.dart';

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
          builder: (context, state) => const MarketHomeScreen(),
        ),
        GoRoute(
          path: RouteNames.favorites,
          name: RouteNames.favoritesName,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('المفضلة')),
            body: const Center(child: Text('قائمة الإعلانات المفضلة')),
          ),
        ),
        GoRoute(
          path: RouteNames.profile,
          name: RouteNames.profileName,
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('حسابي')),
            body: const Center(child: Text('الملف الشخصي والحسابات')),
          ),
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
