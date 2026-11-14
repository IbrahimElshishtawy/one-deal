import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Full-width outlined secondary action button used across auth & modal sheets.
class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final Color? borderColor;
  final Color? foregroundColor;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedForeground =
        foregroundColor ?? AuthDesignTokens.headingOf(context);
    final resolvedBorder = borderColor ?? AuthDesignTokens.borderOf(context);

    return SizedBox(
      width: double.infinity,
      height: AuthDesignTokens.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedForeground,
          side: BorderSide(color: resolvedBorder, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthDesignTokens.buttonRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
