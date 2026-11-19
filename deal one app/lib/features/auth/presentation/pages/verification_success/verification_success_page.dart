import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/app_localization.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../domain/entities/auth_session.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/success/success_emblem_widget.dart';

/// Navigation payload for [VerificationSuccessPage].
class VerificationSuccessArgs {
  final AuthSession session;
  final String? redirectTo;

  const VerificationSuccessArgs({required this.session, this.redirectTo});
}

/// Deal One Verification Success screen matching `Success State Screen.png`.
class VerificationSuccessPage extends ConsumerWidget {
  final AuthSession? session;
  final String? redirectTo;

  const VerificationSuccessPage({super.key, this.session, this.redirectTo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final activeUser =
        session?.user ?? ref.watch(authControllerProvider).valueOrNull;
    final hasCustomName =
        activeUser != null &&
        activeUser.fullName.trim().isNotEmpty &&
        !activeUser.fullName.trim().startsWith('مستخدم ');

    final targetRoute =
        (redirectTo != null &&
            redirectTo!.startsWith('/') &&
            redirectTo != RouteNames.login &&
            redirectTo != RouteNames.signUp)
        ? redirectTo!
        : RouteNames.root;

    return AuthScaffoldShell(
      centerVertically: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                l10n.authBrandNameAr,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AuthDesignTokens.headingOf(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AuthDesignTokens.spaceXs),
              Text(
                l10n.authBrandNameEn,
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
          const SuccessEmblemWidget(),
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
                ? l10n.successSubtitlePersonalized(activeUser.fullName)
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
            onPressed: () => context.go(targetRoute),
          ),
        ],
      ),
    );
  }
}
