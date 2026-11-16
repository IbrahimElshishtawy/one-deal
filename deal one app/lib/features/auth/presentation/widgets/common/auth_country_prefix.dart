import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';

/// Compact Egyptian `+20` country prefix pill shown inside phone inputs.
class AuthCountryPrefixBadge extends StatelessWidget {
  final bool compact;

  const AuthCountryPrefixBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: compact
            ? AuthDesignTokens.softPillOf(context)
            : AuthDesignTokens.surfaceOf(context),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: compact
            ? null
            : Border.all(color: AuthDesignTokens.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _EgyptFlagStripes(),
          const SizedBox(width: 5),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '+20',
              style: TextStyle(
                fontSize: compact ? 12 : 13.5,
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
      borderRadius: BorderRadius.circular(2.5),
      child: const SizedBox(
        width: 16,
        height: 11,
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
