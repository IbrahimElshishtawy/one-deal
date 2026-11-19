import 'package:flutter/material.dart';

import '../../../../../app/app_localization.dart';
import '../../theme/auth_design_tokens.dart';

/// Floating rose/pink alert card matching
/// `Verification via OTP code _Timeout State_.png`.
class OtpExpiredCard extends StatelessWidget {
  const OtpExpiredCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final errorFg = AuthDesignTokens.errorForegroundOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthDesignTokens.expiredCardOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AuthDesignTokens.surfaceOf(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_off_outlined, size: 24, color: errorFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.otpExpiredTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: errorFg,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.otpExpiredBody,
                  style: TextStyle(fontSize: 12.5, color: errorFg, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
