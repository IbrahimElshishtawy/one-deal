import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Displays both the OTP expiry indicator and interactive resend cooldown action.
class OtpCountdownTimer extends StatelessWidget {
  final String formattedCooldown;
  final String formattedExpiry;
  final int cooldownRemainingSeconds;
  final bool isExpired;
  final bool isResending;
  final bool canResend;
  final VoidCallback onResendPressed;

  const OtpCountdownTimer({
    super.key,
    required this.formattedCooldown,
    required this.formattedExpiry,
    required this.cooldownRemainingSeconds,
    required this.isExpired,
    required this.isResending,
    required this.canResend,
    required this.onResendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isExpired
            ? AuthDesignTokens.errorTintOf(context)
            : AuthDesignTokens.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpired
              ? AuthDesignTokens.errorBorder
              : AuthDesignTokens.borderOf(context),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isExpired
                        ? AuthDesignTokens.errorRed
                        : AuthDesignTokens.mutedOf(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpired ? 'انتهت صلاحية الرمز' : 'صلاحية الرمز المتبقية',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isExpired
                          ? AuthDesignTokens.errorRed
                          : AuthDesignTokens.mutedOf(context),
                    ),
                  ),
                ],
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  isExpired ? '00:00' : formattedExpiry,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isExpired
                        ? AuthDesignTokens.errorRed
                        : AuthDesignTokens.headingOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AuthDesignTokens.dividerOf(context)),
          const SizedBox(height: 10),
          if (cooldownRemainingSeconds > 0 && !isResending)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'إعادة إرسال الرمز خلال ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    formattedCooldown,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AuthDesignTokens.focusOrange,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const Key('otp_resend_button'),
                onPressed: canResend ? onResendPressed : null,
                icon: isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AuthDesignTokens.actionBlue,
                      ),
                label: Text(
                  isResending ? 'جاري إرسال رمز جديد...' : 'إعادة إرسال الرمز',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: canResend
                        ? AuthDesignTokens.actionBlue
                        : AuthDesignTokens.mutedOf(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
