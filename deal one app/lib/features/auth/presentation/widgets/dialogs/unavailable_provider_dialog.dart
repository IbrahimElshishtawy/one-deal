import 'package:flutter/material.dart';

import '../../../../../app/app_localization.dart';
import '../../../domain/entities/auth_session.dart';
import '../../theme/auth_design_tokens.dart';

/// Informative modal dialog shown when tapping Email or Apple social buttons,
/// transparently explaining that authentication currently runs over Egyptian SMS OTP.
class UnavailableProviderDialog extends StatelessWidget {
  final SocialAuthProviderType provider;

  const UnavailableProviderDialog({super.key, required this.provider});

  static Future<void> show(
    BuildContext context, {
    required SocialAuthProviderType provider,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => UnavailableProviderDialog(provider: provider),
    );
  }

  String _providerLabel(AppLocalizations l10n) {
    switch (provider) {
      case SocialAuthProviderType.google:
        return l10n.authEmailProvider;
      case SocialAuthProviderType.apple:
        return l10n.authAppleProvider;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final providerName = _providerLabel(l10n);

    return AlertDialog(
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AuthDesignTokens.infoTintOf(context),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline_rounded,
          color: AuthDesignTokens.linkOf(context),
          size: 28,
        ),
      ),
      title: Text(
        l10n.unavailableProviderTitle(providerName),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w800,
          color: AuthDesignTokens.headingOf(context),
        ),
      ),
      content: Text(
        l10n.unavailableProviderBody,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: AuthDesignTokens.bodyOf(context),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AuthDesignTokens.primaryActionOf(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              l10n.unavailableProviderCta,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
