import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Standard legal footer shown at the bottom of Deal One auth screens.
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
          const TextSpan(text: 'بالمتابعة، فإنك توافق على '),
          TextSpan(
            text: 'شروط الخدمة',
            recognizer: widget.onTermsTap != null ? _termsRecognizer : null,
            style: linkStyle,
          ),
          const TextSpan(text: ' و'),
          TextSpan(
            text: 'سياسة الخصوصية',
            recognizer: widget.onPrivacyTap != null ? _privacyRecognizer : null,
            style: linkStyle,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
