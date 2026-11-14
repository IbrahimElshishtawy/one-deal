import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_settings_providers.dart';
import '../core/providers/core_providers.dart';
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

class _MarketSpaceAppState extends ConsumerState<MarketSpaceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final initialRoute = widget.dependencies.onboardingCompleted
        ? RouteNames.root
        : RouteNames.onboarding;
    _router =
        widget.customRouter ??
        AppRouter.createRouter(initialLocation: initialRoute);
    Future.microtask(() => ref.read(sessionProvider.notifier).restoreSession());
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
        localizationsDelegates: AppLocalization.localizationsDelegates,
        supportedLocales: AppLocalization.supportedLocales,
      ),
    );
  }
}
