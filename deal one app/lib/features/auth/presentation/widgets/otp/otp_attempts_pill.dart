import 'package:flutter/material.dart';

import '../../../../../app/app_localization.dart';
import '../../theme/auth_design_tokens.dart';

/// Soft pill badge showing remaining OTP attempts before temporary lock,
/// matching `Verification via OTP code _Faild State_.png`.
class OtpAttemptsPill extends StatelessWidget {
  final int remainingAttempts;

  const OtpAttemptsPill({super.key, required this.remainingAttempts});

  String _label(AppLocalizations l10n) {
    if (remainingAttempts == 1) {
      return l10n.otpRemainingAttemptOne;
    }
    if (remainingAttempts == 2) {
      return l10n.otpRemainingAttemptTwo;
    }
    return l10n.otpRemainingAttemptsMany(remainingAttempts);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

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
              Icons.lock_clock_outlined,
              size: 15,
              color: AuthDesignTokens.mutedOf(context),
            ),
            const SizedBox(width: AuthDesignTokens.spaceSm - 2),
            Flexible(
              child: Text(
                _label(l10n),
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
