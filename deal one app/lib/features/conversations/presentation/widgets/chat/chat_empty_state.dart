import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style empty conversation card over the chat wallpaper
/// with clickable starter prompt pills.
class ChatEmptyState extends StatelessWidget {
  final String counterpartName;
  final ChatColorTheme colorTheme;
  final ValueChanged<String> onPromptSelected;

  const ChatEmptyState({
    super.key,
    required this.counterpartName,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onPromptSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    final prompts = isArabic
        ? const [
            'السلام عليكم، هل العرض متاح؟',
            'ممكن تفاصيل السعر النهائي؟',
            'متى يمكن تحديد موعد للمعاينة؟',
          ]
        : const [
            'Hello, is this still available?',
            'Could you share the final price?',
            'When can we arrange a viewing?',
          ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: DealOneTokens.cardSurfaceOf(context).withValues(
              alpha: isDark ? 0.88 : 0.94,
            ),
            borderRadius: AppRadii.xl,
            border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            boxShadow: DealOneTokens.cardShadow(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 28,
                  color: accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic
                    ? 'ابدأ المحادثة مع $counterpartName'
                    : 'Start chatting with $counterpartName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isArabic
                    ? 'اختر رسالة سريعة أو اكتب استفسارك بالأسفل.'
                    : 'Pick a quick starter below or type your inquiry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: prompts.map((p) {
                  return ActionChip(
                    backgroundColor: accent.withValues(
                      alpha: isDark ? 0.18 : 0.08,
                    ),
                    side: BorderSide(color: accent.withValues(alpha: 0.25)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.full,
                    ),
                    label: Text(
                      p,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    onPressed: () => onPromptSelected(p),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
