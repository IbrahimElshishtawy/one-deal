import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Soft red/pink banner displayed for OTP invalid, expired, or API errors.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AuthDesignTokens.errorTintOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthDesignTokens.errorBorder, width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AuthDesignTokens.errorRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AuthDesignTokens.errorRed,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onActionPressed,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.actionBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
