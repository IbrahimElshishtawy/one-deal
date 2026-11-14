import 'package:flutter/material.dart';

import '../../../domain/entities/auth_session.dart';
import '../../theme/auth_design_tokens.dart';

/// Social authentication divider and Google / Apple provider action buttons.
class AuthSocialSection extends StatelessWidget {
  final ValueChanged<SocialAuthProviderType> onProviderSelected;

  const AuthSocialSection({
    super.key,
    required this.onProviderSelected,
  });

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
                  fontSize: 13,
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SocialProviderButton(
                label: 'Google',
                icon: const _GoogleGMark(),
                onPressed: () =>
                    onProviderSelected(SocialAuthProviderType.google),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialProviderButton(
                label: 'Apple',
                icon: Icon(
                  Icons.apple,
                  size: 22,
                  color: AuthDesignTokens.headingOf(context),
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
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AuthDesignTokens.inputFillOf(context),
          foregroundColor: AuthDesignTokens.headingOf(context),
          side: BorderSide(color: AuthDesignTokens.borderOf(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthDesignTokens.buttonRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  const _GoogleGMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}
