import 'package:flutter/material.dart';

import '../../../domain/entities/auth_session.dart';
import '../../theme/auth_design_tokens.dart';
import 'auth_brand_icons.dart';

/// Social authentication divider and Email / Apple provider action buttons
/// matching `login.png` and `انشاء حساب.png`.
class AuthSocialSection extends StatelessWidget {
  final ValueChanged<SocialAuthProviderType> onProviderSelected;

  const AuthSocialSection({super.key, required this.onProviderSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AuthDesignTokens.dividerOf(context),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'أو المتابعة عبر',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AuthDesignTokens.mutedOf(context),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AuthDesignTokens.dividerOf(context),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuthDesignTokens.spaceBase),
        Row(
          children: [
            Expanded(
              child: _SocialProviderButton(
                key: const Key('social_email_button'),
                label: 'البريد الإلكتروني',
                icon: const GmailMarkIcon(size: 20),
                onPressed: () =>
                    onProviderSelected(SocialAuthProviderType.google),
              ),
            ),
            const SizedBox(width: AuthDesignTokens.spaceMd),
            Expanded(
              child: _SocialProviderButton(
                key: const Key('social_apple_button'),
                label: 'حساب آبل',
                icon: Icon(
                  Icons.apple,
                  size: 22,
                  color: AuthDesignTokens.isDark(context)
                      ? Colors.white
                      : Colors.black,
                ),
                onPressed: () =>
                    onProviderSelected(SocialAuthProviderType.apple),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialProviderButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialProviderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AuthDesignTokens.socialButtonHeight,
      decoration: BoxDecoration(
        color: AuthDesignTokens.surfaceOf(context),
        borderRadius: BorderRadius.circular(AuthDesignTokens.buttonRadius),
        border: Border.all(color: AuthDesignTokens.borderOf(context)),
        boxShadow: AuthDesignTokens.cardShadowOf(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AuthDesignTokens.buttonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AuthDesignTokens.buttonRadius),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AuthDesignTokens.headingOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
