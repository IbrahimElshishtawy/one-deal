import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Independent circular conversation avatar with verified badge and
/// theme-tinted monogram fallback.
class InboxConversationAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final bool isVerified;
  final double size;
  final ChatColorTheme colorTheme;

  const InboxConversationAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.isVerified = false,
    this.size = 50,
    this.colorTheme = ChatColorTheme.dealOneNavy,
  });

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'D';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = colorTheme.accent(isDark);
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: accent.withValues(alpha: 0.14),
          backgroundImage: hasUrl ? NetworkImage(imageUrl!) : null,
          child: hasUrl
              ? null
              : Text(
                  _initial(displayName),
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
        ),
        if (isVerified)
          PositionedDirectional(
            end: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: DealOneTokens.cardSurfaceOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 15,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }
}
