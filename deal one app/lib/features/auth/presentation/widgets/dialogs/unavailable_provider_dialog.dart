import 'package:flutter/material.dart';

import '../../../domain/entities/auth_session.dart';
import '../../theme/auth_design_tokens.dart';

/// Informative modal dialog shown when tapping Google or Apple social buttons,
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

  String get _providerLabel {
    switch (provider) {
      case SocialAuthProviderType.google:
        return 'Google';
      case SocialAuthProviderType.apple:
        return 'Apple';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AuthDesignTokens.actionBlueTint,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          color: AuthDesignTokens.actionBlue,
          size: 28,
        ),
      ),
      title: Text(
        'التسجيل عبر $_providerLabel غير مفعل حالياً',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w800,
          color: AuthDesignTokens.headingOf(context),
        ),
      ),
      content: Text(
        'يدعم نظام ديل ون حالياً التسجيل والتحقق الآمن عبر رقم الهاتف المصري ورمز التحقق (OTP). يرجى إدخال رقم هاتفك للمتابعة.',
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
            child: const Text(
              'فهمت، المتابعة برقم الهاتف',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
