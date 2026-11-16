import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Displays the official Deal One emblem (`assets/image/logo.png`) cleanly without
/// an enclosing box, paired with localized heading and subtitle copy.
class AuthLogoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoSize;

  const AuthLogoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize = AuthDesignTokens.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'deal_one_auth_logo',
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: logoSize,
              child: Image.asset(
                AuthDesignTokens.logoAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: logoSize * 0.55,
                        color: AuthDesignTokens.primaryActionOf(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ديل ون',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AuthDesignTokens.headingOf(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
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
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AuthDesignTokens.mutedOf(context),
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}
