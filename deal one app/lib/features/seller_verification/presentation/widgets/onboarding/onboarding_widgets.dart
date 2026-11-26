import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

class SellerOnboardingHeader extends StatelessWidget {
  const SellerOnboardingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? const [AppColors.darkSurface, AppColors.darkSurfaceElevated]
              : const [DealOneTokens.navy, DealOneTokens.navySoft],
        ),
        borderRadius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: AppRadii.md,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            s.onboardingHeadline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.onboardingSubtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class SellerBenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SellerBenefitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DealOneTokens.softTileBgOf(context),
              borderRadius: AppRadii.md,
            ),
            child: Icon(
              icon,
              color: DealOneTokens.textPrimaryOf(context),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SellerBenefitsSection extends StatelessWidget {
  const SellerBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.benefitsSectionTitle,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SellerBenefitCard(
          icon: Icons.verified_rounded,
          title: s.benefitTrustTitle,
          description: s.benefitTrustDesc,
        ),
        const SizedBox(height: AppSpacing.sm),
        SellerBenefitCard(
          icon: Icons.storefront_outlined,
          title: s.benefitVisibilityTitle,
          description: s.benefitVisibilityDesc,
        ),
        const SizedBox(height: AppSpacing.sm),
        SellerBenefitCard(
          icon: Icons.trending_up_rounded,
          title: s.benefitUpgradeTitle,
          description: s.benefitUpgradeDesc,
        ),
      ],
    );
  }
}

class VerificationSecurityNotice extends StatelessWidget {
  const VerificationSecurityNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationNoticeBanner(
      title: s.securityNoticeTitle,
      message: s.securityNoticeBody,
      tone: VerificationNoticeTone.info,
      icon: Icons.lock_outline_rounded,
    );
  }
}

class StartSellingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const StartSellingButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return ContinueButton(
      label: s.startSellingCta,
      icon: Icons.rocket_launch_outlined,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

class ExistingApplicationStatusCard extends StatelessWidget {
  final VerificationStatusSnapshot snapshot;
  final VoidCallback onTrackTap;

  const ExistingApplicationStatusCard({
    super.key,
    required this.snapshot,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      borderColor: DealOneTokens.amberBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.warningOf(context),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.existingApplicationTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.statusLabel(snapshot.sellerStatus),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ContinueButton(
            label: s.viewApplicationStatusCta,
            icon: Icons.timeline_rounded,
            onPressed: onTrackTap,
          ),
        ],
      ),
    );
  }
}
