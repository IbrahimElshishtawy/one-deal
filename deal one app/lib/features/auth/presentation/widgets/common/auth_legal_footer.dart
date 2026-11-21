import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';

/// Standard localized legal footer shown at the bottom of Deal One auth screens.
class AuthLegalFooter extends StatefulWidget {
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const AuthLegalFooter({super.key, this.onTermsTap, this.onPrivacyTap});

  @override
  State<AuthLegalFooter> createState() => _AuthLegalFooterState();
}

class _AuthLegalFooterState extends State<AuthLegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant AuthLegalFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTermsTap;
    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final baseStyle = TextStyle(
      fontSize: 11.5,
      height: 1.5,
      color: AuthDesignTokens.mutedOf(context),
    );
    final linkStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AuthDesignTokens.bodyOf(context),
      decoration: widget.onTermsTap != null || widget.onPrivacyTap != null
          ? TextDecoration.underline
          : TextDecoration.none,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: l10n.authLegalPrefix),
          TextSpan(
            text: l10n.authLegalTerms,
            recognizer: widget.onTermsTap != null ? _termsRecognizer : null,
            style: linkStyle,
          ),
          TextSpan(text: l10n.authLegalAnd),
          TextSpan(
            text: l10n.authLegalPrivacy,
            recognizer: widget.onPrivacyTap != null ? _privacyRecognizer : null,
            style: linkStyle,
          ),
          TextSpan(text: l10n.authLegalSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
