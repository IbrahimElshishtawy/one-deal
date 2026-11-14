import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Displays the official Deal One handshake emblem (`assets/image/logo.png`)
/// paired with optional localized heading and subtitle copy.
class AuthLogoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoSize;

  const AuthLogoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: AuthDesignTokens.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AuthDesignTokens.borderOf(context),
            ),
            boxShadow: [
              BoxShadow(
                color: AuthDesignTokens.navyPrimary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              AuthDesignTokens.logoAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.handshake_outlined,
                  size: logoSize * 0.5,
                  color: AuthDesignTokens.primaryActionOf(context),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AuthDesignTokens.headingOf(context),
            height: 1.3,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AuthDesignTokens.mutedOf(context),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
