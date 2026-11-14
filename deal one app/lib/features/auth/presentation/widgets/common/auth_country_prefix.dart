import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Compact Egyptian `+20` country prefix pill shown inside phone inputs.
class AuthCountryPrefixBadge extends StatelessWidget {
  const AuthCountryPrefixBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuthDesignTokens.surfaceOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuthDesignTokens.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _EgyptFlagStripes(),
          const SizedBox(width: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '+20',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AuthDesignTokens.headingOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EgyptFlagStripes extends StatelessWidget {
  const _EgyptFlagStripes();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: const SizedBox(
        width: 18,
        height: 12,
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFCE1126))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFF111827))),
          ],
        ),
      ),
    );
  }
}
