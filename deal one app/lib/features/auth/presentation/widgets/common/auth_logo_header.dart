import 'package:flutter/material.dart';

import 'package:market_space/core/design_system/deal_one_logo.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';

/// Displays the official DealOne emblem (`assets/image/logo.png`) cleanly without
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
            child: DealOneLogo(
              height: logoSize,
              showDarkModeGlow: true,
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
