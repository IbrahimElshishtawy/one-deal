import 'package:flutter/widgets.dart';

import 'package:market_space/core/security/token_provider.dart';
import 'package:market_space/core/routing/route_names.dart';

abstract class RouteGuard {
  Future<String?> evaluateRedirect(BuildContext context, String currentRoute);
}

/// Evaluates route access against live session authentication state and stored tokens.
class SessionRouteGuard implements RouteGuard {
  final TokenProvider tokenProvider;
  final bool Function()? isAuthenticatedProvider;

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {
    RouteNames.favorites,
    RouteNames.myActivity,
    RouteNames.globalNotifications,
    RouteNames.buildingMaterialsCart,
    RouteNames.buildingMaterialsCheckout,
    RouteNames.buildingMaterialsOrders,
    RouteNames.buildingMaterialsOrderDetail,
    RouteNames.buildingMaterialsNotifications,
    RouteNames.buildingMaterialsRfq,
    RouteNames.fashionCart,
    RouteNames.homeServicesBookings,
    RouteNames.homeServicesFavorites,
    RouteNames.homeServicesNotifications,
    RouteNames.homeServicesBookingWizard,
    RouteNames.homeServicesBookingDetail,
    RouteNames.homeServicesTechnicianTracking,
  };

  /// Authentication entry routes redirected away once authenticated.
  /// Excludes OTP verification & verification success so the in-progress
  /// verification flow transitions naturally to `VerificationSuccessPage`.
  static const Set<String> authEntryRoutes = {
    RouteNames.login,
    RouteNames.signUp,
  };

  SessionRouteGuard({
    required this.tokenProvider,
    this.isAuthenticatedProvider,
  });

  static bool isProtectedPath(String path) => protectedRoutes.contains(path);

  static bool isAuthEntryPath(String path) => authEntryRoutes.contains(path);

  @override
  Future<String?> evaluateRedirect(
    BuildContext context,
    String currentRoute,
  ) async {
    final uri = Uri.tryParse(currentRoute);
    final path = uri?.path ?? currentRoute;
    final hasValidSession =
        isAuthenticatedProvider?.call() ?? await tokenProvider.hasValidToken();

    if (!hasValidSession && isProtectedPath(path)) {
      final encodedTarget = Uri.encodeComponent(currentRoute);
      return '${RouteNames.login}?redirect=$encodedTarget';
    }

    if (hasValidSession && isAuthEntryPath(path)) {
      final redirectParam = uri?.queryParameters['redirect'];
      if (redirectParam != null &&
          redirectParam.startsWith('/') &&
          !isAuthEntryPath(redirectParam)) {
        return redirectParam;
      }
      return RouteNames.root;
    }

    return null;
  }
}
