import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style bottom attachment / quick-action grid sheet for deal actions.
class ChatAttachmentSheet extends StatelessWidget {
  final ChatColorTheme colorTheme;
  final ValueChanged<String> onTemplateSelected;

  const ChatAttachmentSheet({
    super.key,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onTemplateSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required ChatColorTheme colorTheme,
    required ValueChanged<String> onTemplateSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: DealOneTokens.cardSurfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ChatAttachmentSheet(
        colorTheme: colorTheme,
        onTemplateSelected: onTemplateSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    final items = [
      (
        icon: Icons.calendar_month_rounded,
        color: accent,
        label: isArabic ? 'طلب معاينة' : 'Request Viewing',
        template: isArabic
            ? 'مرحباً، أود تحديد موعد مناسب للمعاينة.'
            : 'Hello, I would like to schedule a viewing.',
      ),
      (
        icon: Icons.payments_outlined,
        color: DealOneTokens.amber,
        label: isArabic ? 'تفاوض على السعر' : 'Price Inquiry',
        template: isArabic
            ? 'هل السعر قابل للتفاوض الجاد؟'
            : 'Is the listed price negotiable?',
      ),
      (
        icon: Icons.location_on_outlined,
        color: DealOneTokens.successGreen,
        label: isArabic ? 'طلب الموقع' : 'Request Location',
        template: isArabic
            ? 'ممكن مشاركة تفاصيل العنوان أو الموقع الدقيق؟'
            : 'Could you please share the exact location details?',
      ),
      (
        icon: Icons.schedule_rounded,
        color: const Color(0xFF7C3AED),
        label: isArabic ? 'تأكيد التوفر' : 'Availability',
        template: isArabic
            ? 'هل العرض ما زال متاحاً للتعاقد الآن؟'
            : 'Is this offer still available right now?',
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: DealOneTokens.cardBorderOf(context),
                borderRadius: AppRadii.full,
              ),
            ),
            Text(
              isArabic ? 'إجراءات سريعة للصفقة' : 'Quick Deal Actions',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.2,
              children: items.map((item) {
                return InkWell(
                  borderRadius: AppRadii.md,
                  onTap: () {
                    Navigator.of(context).pop();
                    onTemplateSelected(item.template);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: AppRadii.md,
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: item.color,
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
