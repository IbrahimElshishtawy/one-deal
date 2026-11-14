import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Help links shown below OTP verification for delivery troubleshooting and support.
class OtpDeliveryHelpRow extends StatelessWidget {
  final VoidCallback onDeliveryTroubleTap;
  final VoidCallback onSupportTap;

  const OtpDeliveryHelpRow({
    super.key,
    required this.onDeliveryTroubleTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          key: const Key('otp_delivery_help_button'),
          onPressed: onDeliveryTroubleTap,
          icon: const Icon(
            Icons.help_outline_rounded,
            size: 18,
            color: AuthDesignTokens.actionBlue,
          ),
          label: const Text(
            'لم يصلك الرمز عبر واتساب؟',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AuthDesignTokens.actionBlue,
            ),
          ),
        ),
        TextButton(
          key: const Key('otp_support_button'),
          onPressed: onSupportTap,
          child: Text(
            'تواصل مع الدعم الفني',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AuthDesignTokens.mutedOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
