import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// In-chat message search bar with match counter and previous/next navigation.
class ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final int totalMatches;
  final int currentMatchIndex;
  final ChatColorTheme colorTheme;
  final ValueChanged<String> onChanged;
  final VoidCallback onPreviousMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onClose;

  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.totalMatches,
    required this.currentMatchIndex,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onChanged,
    required this.onPreviousMatch,
    required this.onNextMatch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);
    final queryNotEmpty = controller.text.trim().isNotEmpty;

    return Container(
      key: const Key('chat_search_bar'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        border: Border(
          bottom: BorderSide(color: DealOneTokens.cardBorderOf(context)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              key: const Key('chat_search_input'),
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 14,
                color: DealOneTokens.textPrimaryOf(context),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: isArabic
                    ? 'ابحث داخل المحادثة...'
                    : 'Search in conversation...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
                filled: true,
                fillColor: DealOneTokens.inputFillOf(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadii.full,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (queryNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              totalMatches == 0
                  ? '0/0'
                  : '${currentMatchIndex + 1}/$totalMatches',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: totalMatches == 0
                    ? DealOneTokens.dangerRed
                    : DealOneTokens.textSecondaryOf(context),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isArabic ? 'النتيجة السابقة' : 'Previous match',
              onPressed: totalMatches > 0 ? onPreviousMatch : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isArabic ? 'النتيجة التالية' : 'Next match',
              onPressed: totalMatches > 0 ? onNextMatch : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ),
          ],
          IconButton(
            key: const Key('chat_search_close_button'),
            visualDensity: VisualDensity.compact,
            tooltip: isArabic ? 'إغلاق البحث' : 'Close search',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}
