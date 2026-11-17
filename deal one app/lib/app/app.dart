import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_settings_providers.dart';
import '../core/providers/core_providers.dart';
import '../core/routing/route_guards.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_theme_data.dart';
import 'app_dependencies.dart';
import 'app_localization.dart';
import 'app_router.dart';

class MarketSpaceApp extends ConsumerStatefulWidget {
  final AppDependencies dependencies;
  final GoRouter? customRouter;

  const MarketSpaceApp({
    super.key,
    required this.dependencies,
    this.customRouter,
  });

  @override
  ConsumerState<MarketSpaceApp> createState() => _MarketSpaceAppState();
}

class _SessionRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _MarketSpaceAppState extends ConsumerState<MarketSpaceApp> {
  late final GoRouter _router;
  final _SessionRefreshNotifier _refreshNotifier = _SessionRefreshNotifier();
  ProviderSubscription<dynamic>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    final initialRoute = widget.dependencies.onboardingCompleted
        ? RouteNames.root
        : RouteNames.onboarding;
    final routeGuard = SessionRouteGuard(
      tokenProvider: ref.read(tokenProvider),
      isAuthenticatedProvider: () => ref.read(sessionProvider).isAuthenticated,
    );
    _sessionSubscription = ref.listenManual(sessionProvider, (_, _) {
      _refreshNotifier.notify();
    });
    _router =
        widget.customRouter ??
        AppRouter.createRouter(
          routeGuard: routeGuard,
          refreshListenable: _refreshNotifier,
          initialLocation: initialRoute,
        );
    Future.microtask(() => ref.read(sessionProvider.notifier).restoreSession());
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(appLocaleProvider);
    final currentThemeMode = ref.watch(appThemeModeProvider);

    return AppDependenciesScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        title: 'Deal One (صفقة ون)',
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        locale: currentLocale,
        themeMode: currentThemeMode,
        theme: AppThemeData.lightTheme,
        darkTheme: AppThemeData.darkTheme,
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: isDark
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        localizationsDelegates: AppLocalization.localizationsDelegates,
        supportedLocales: AppLocalization.supportedLocales,
      ),
    );
  }
}
