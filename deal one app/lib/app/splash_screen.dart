import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/constants/app_constants.dart';
import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';

/// Branded launch splash screen for DealOne displaying `assets/image/logo.png`
/// with preserved aspect ratio before transitioning to [nextRoute].
class SplashScreen extends StatefulWidget {
  final String nextRoute;
  final Duration delay;

  const SplashScreen({
    super.key,
    this.nextRoute = RouteNames.root,
    this.delay = AppConstants.splashDelayDuration,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    context.go(widget.nextRoute);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('deal_one_splash_screen'),
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DealOneLogo(
                  key: Key('splash_brand_logo'),
                  height: 168,
                  showDarkModeGlow: true,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white : DealOneDesignColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
