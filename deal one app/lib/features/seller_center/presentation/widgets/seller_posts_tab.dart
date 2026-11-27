import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Posts Management Tab.
/// Deal One V1 separates marketplace Advertisements (`Listing`) from Social Posts.
/// Because the current V1 backend schema does not yet include a dedicated social
/// `Post` / `Comment` model, this tab transparently communicates that boundary
/// without inventing fake posts or synthetic engagement metrics.
class SellerPostsTab extends StatelessWidget {
  final VoidCallback onOpenAdvertisements;

  const SellerPostsTab({super.key, required this.onOpenAdvertisements});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        DealOneEmptyStateView(
          icon: Icons.article_outlined,
          title: isArabic
              ? 'إدارة المنشورات الاجتماعية (قريباً في V2)'
              : 'Social Posts Management (Planned V2)',
          description: isArabic
              ? 'في الإصدار الحالي من Deal One V1، يتم إدارة العروض والخدمات من خلال قسم "إعلاناتي" المنفصل. لم يتم تفعيل جدول منشورات اجتماعية وتعليقات مستقل في الخادم بعد.'
              : 'Deal One V1 keeps Marketplace Advertisements separate from Social Posts. Dedicated seller social posts, comments, and pinning are not yet enabled in the V1 backend.',
          actionLabel: isArabic ? 'الذهاب إلى إعلاناتي' : 'Go to My Ads',
          actionIcon: Icons.campaign_outlined,
          onAction: onOpenAdvertisements,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: DealOneTokens.cardDecoration(context),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: DealOneTokens.navy),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isArabic
                      ? 'لا يتم عرض أي منشورات أو تعليقات وهمية؛ ستظهر هنا تلقائياً فور تفعيل واجهة المنشورات بالخادم.'
                      : 'No synthetic posts or comments are shown; real posts will appear automatically once the backend posts API is provisioned.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
