import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Clean Telegram-style inbox search bar with live clear button.
class InboxSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ChatColorTheme colorTheme;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const InboxSearchBar({
    super.key,
    required this.controller,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);
    final hasText = controller.text.isNotEmpty;

    return Container(
      key: const Key('inbox_search_bar'),
      decoration: DealOneTokens.cardDecoration(
        context,
        borderRadius: AppRadii.full,
      ),
      child: TextField(
        key: const Key('inbox_search_input'),
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: DealOneTokens.textPrimaryOf(context),
        ),
        decoration: InputDecoration(
          hintText: isArabic
              ? 'ابحث في المحادثات أو الإعلانات...'
              : 'Search conversations or listings...',
          hintStyle: TextStyle(
            fontSize: 13.5,
            color: DealOneTokens.textSecondaryOf(context),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: hasText ? accent : DealOneTokens.textSecondaryOf(context),
          ),
          suffixIcon: hasText
              ? IconButton(
                  key: const Key('inbox_search_clear_button'),
                  tooltip: isArabic ? 'مسح البحث' : 'Clear search',
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
