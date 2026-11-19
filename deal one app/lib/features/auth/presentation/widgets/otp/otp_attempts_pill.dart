import 'package:flutter/material.dart';

import '../../l10n/auth_l10n_extension.dart';
import '../../theme/auth_design_tokens.dart';

/// Soft rounded pill displaying remaining OTP verification attempts
/// matching `Verification via OTP code _Faild State_.png`.
class OtpAttemptsPill extends StatelessWidget {
  final int remainingAttempts;

  const OtpAttemptsPill({super.key, required this.remainingAttempts});

  String _message(BuildContext context) {
    final l10n = context.authL10n;
    if (remainingAttempts == 1) return l10n.otpRemainingAttemptsOne;
    if (remainingAttempts == 2) return l10n.otpRemainingAttemptsTwo;
    return l10n.otpRemainingAttemptsMany(remainingAttempts);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AuthDesignTokens.spaceBase,
          vertical: AuthDesignTokens.spaceSm - 2,
        ),
        decoration: BoxDecoration(
          color: AuthDesignTokens.softPillOf(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AuthDesignTokens.mutedOf(context),
            ),
            const SizedBox(width: AuthDesignTokens.spaceSm - 2),
            Flexible(
              child: Text(
                _message(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AuthDesignTokens.bodyOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
