import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style Archived Chats folder row displayed at the top of the inbox
/// whenever there is at least one archived conversation.
class InboxArchivedFolderTile extends StatelessWidget {
  final int archivedCount;
  final String previewNames;
  final ChatColorTheme colorTheme;
  final VoidCallback onTap;

  const InboxArchivedFolderTile({
    super.key,
    required this.archivedCount,
    required this.previewNames,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return Material(
      key: const Key('inbox_archived_folder_tile'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: DealOneTokens.cardDecoration(context),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: DealOneTokens.softTileBgOf(context),
                child: Icon(
                  Icons.archive_outlined,
                  size: 21,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isArabic ? 'المحادثات المؤرشفة' : 'Archived Chats',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    if (previewNames.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        previewNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: DealOneTokens.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  '$archivedCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
