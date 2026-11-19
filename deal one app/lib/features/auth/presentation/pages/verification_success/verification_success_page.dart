import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../domain/entities/auth_session.dart';
import '../../l10n/auth_l10n_extension.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/success/success_badge_widget.dart';

/// Navigation payload for [VerificationSuccessPage].
class VerificationSuccessArgs {
  final AuthSession session;
  final String? redirectTo;

  const VerificationSuccessArgs({required this.session, this.redirectTo});
}

/// Deal One Verification Success screen matching `Success State Screen.png`.
class VerificationSuccessPage extends ConsumerStatefulWidget {
  final AuthSession? session;
  final String? redirectTo;

  const VerificationSuccessPage({super.key, this.session, this.redirectTo});

  @override
  ConsumerState<VerificationSuccessPage> createState() =>
      _VerificationSuccessPageState();
}

class _VerificationSuccessPageState
    extends ConsumerState<VerificationSuccessPage> {
  bool _navigated = false;

  void _handleContinue(String targetRoute) {
    if (_navigated) return;
    _navigated = true;
    context.go(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final activeUser =
        widget.session?.user ?? ref.watch(authControllerProvider).valueOrNull;
    final hasCustomName =
        activeUser != null &&
        activeUser.fullName.trim().isNotEmpty &&
        !activeUser.fullName.trim().startsWith('مستخدم ');

    final targetRoute =
        (widget.redirectTo != null &&
            widget.redirectTo!.startsWith('/') &&
            widget.redirectTo != RouteNames.login &&
            widget.redirectTo != RouteNames.signUp)
        ? widget.redirectTo!
        : RouteNames.root;

    return AuthScaffoldShell(
      centerVertically: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                l10n.brandNameAr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AuthDesignTokens.headingOf(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AuthDesignTokens.spaceXs),
              Text(
                l10n.brandNameEn,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AuthDesignTokens.headingOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AuthDesignTokens.space3xl),
          const SuccessBadgeWidget(),
          const SizedBox(height: AuthDesignTokens.spaceXl),
          Text(
            l10n.successTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceSm),
          Text(
            hasCustomName
                ? l10n.successSubtitleWithName(activeUser.fullName)
                : l10n.successSubtitleDefault,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.mutedOf(context),
              height: 1.65,
            ),
          ),
          const SizedBox(height: AuthDesignTokens.space2xl),
          AuthPrimaryButton(
            key: const Key('verification_success_continue_button'),
            label: l10n.successContinueButton,
            onPressed: () => _handleContinue(targetRoute),
          ),
        ],
      ),
    );
  }
}
