import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';

/// Business account creation / management banner matching `Profile.png`.
class ProfileBusinessBanner extends StatelessWidget {
  final List<UserAccountEntity> accounts;
  final VoidCallback onStartNow;

  const ProfileBusinessBanner({
    super.key,
    required this.accounts,
    required this.onStartNow,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = AppColors.isDark(context);
    final hasBusiness = accounts.any((a) => a.accountType != 'individual');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: isDark
              ? const [AppColors.darkSurface, AppColors.darkSurfaceElevated]
              : const [Color(0xFFFFFFFF), Color(0xFFFDF5EB)],
        ),
        borderRadius: AppRadii.lg,
        border: Border.all(color: DealOneTokens.cardBorderOf(context)),
        boxShadow: DealOneTokens.cardShadow(context),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackCta = constraints.maxWidth < 310 ||
              context.effectiveTextScale >= 1.5;

          final content = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: DealOneTokens.navy,
                  borderRadius: AppRadii.md,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasBusiness
                          ? (isArabic ? 'حسابك التجاري' : 'Business Account')
                          : (isArabic
                              ? 'إنشاء حساب تجاري'
                              : 'Create Business Account'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasBusiness
                          ? accounts
                              .firstWhere((a) => a.accountType != 'individual')
                              .displayName
                          : (isArabic
                              ? 'مرتبط بحسابك الشخصي لإضافة وإدارة الإعلانات والأنشطة'
                              : 'Linked to your account to publish and manage listings'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final cta = ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
            ),
            onPressed: onStartNow,
            child: Text(
              hasBusiness
                  ? (isArabic ? 'إضافة نشاط' : 'Add New')
                  : (isArabic ? 'ابدأ الآن' : 'Start Now'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          );

          if (stackCta) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: AppSpacing.md),
                cta,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: AppSpacing.sm),
              cta,
            ],
          );
        },
      ),
    );
  }
}
