import 'package:flutter/material.dart';

import 'package:market_space/features/auth/domain/validators/auth_validators.dart';
import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_error_banner.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_primary_button.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_text_field.dart';

/// Email fallback modal with full validation and transparent backend status
/// communication (never fabricates unsupported email OTP delivery).
class EmailFallbackSheet extends StatefulWidget {
  const EmailFallbackSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EmailFallbackSheet(),
    );
  }

  @override
  State<EmailFallbackSheet> createState() => _EmailFallbackSheetState();
}

class _EmailFallbackSheetState extends State<EmailFallbackSheet> {
  final TextEditingController _emailController = TextEditingController();
  EmailValidationError? _emailErrorCode;
  bool _showUnsupportedNotice = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final errorCode = EmailValidator.validateCode(_emailController.text);
    if (errorCode != null) {
      setState(() {
        _emailErrorCode = errorCode;
        _showUnsupportedNotice = false;
      });
      return;
    }

    setState(() {
      _emailErrorCode = null;
      _showUnsupportedNotice = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final localizedEmailError = AuthLocalizedMessages.emailError(
      l10n,
      _emailErrorCode,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AuthDesignTokens.borderOf(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.emailFallbackTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.emailFallbackSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.bodyOf(context),
            ),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            key: const Key('email_fallback_field'),
            label: l10n.emailFallbackLabel,
            hintText: 'name@example.com',
            controller: _emailController,
            errorText: localizedEmailError,
            leadingIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            onChanged: (_) {
              if (_emailErrorCode != null || _showUnsupportedNotice) {
                setState(() {
                  _emailErrorCode = null;
                  _showUnsupportedNotice = false;
                });
              }
            },
            onSubmitted: (_) => _handleSubmit(),
          ),
          if (_showUnsupportedNotice) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(
              key: const Key('email_fallback_notice'),
              message: l10n.emailFallbackUnsupported,
              icon: Icons.info_outline_rounded,
            ),
          ],
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const Key('email_fallback_submit'),
            label: l10n.emailFallbackSubmit,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
