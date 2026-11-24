import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Independent Deal One live advisors status banner shown in the inbox.
class InboxStatusBanner extends StatelessWidget {
  final ChatColorTheme colorTheme;
  final VoidCallback? onDismiss;

  const InboxStatusBanner({
    super.key,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return Container(
      key: const Key('inbox_status_banner'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        8,
        AppSpacing.xs,
        8,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: AppRadii.md,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: DealOneTokens.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isArabic
                  ? 'الردود الفورية نشطة الآن من مستشاري Deal One'
                  : 'Instant replies are active from Deal One advisors',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
          ),
          Icon(Icons.verified_user_outlined, size: 17, color: accent),
          if (onDismiss != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isArabic ? 'إخفاء' : 'Hide',
              onPressed: onDismiss,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
        ],
      ),
    );
  }
}
