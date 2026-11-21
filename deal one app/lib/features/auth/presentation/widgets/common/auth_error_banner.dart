import 'package:flutter/material.dart';

import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';

/// Soft pink/red banner matching `لو المستخدم دخل الرمز غلط.png`.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.icon = Icons.error_rounded,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final errorFg = AuthDesignTokens.errorForegroundOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AuthDesignTokens.errorTintOf(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: errorFg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: errorFg,
                    height: 1.4,
                  ),
                ),
                if (actionLabel != null && onActionPressed != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onActionPressed,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.headingOf(context),
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
