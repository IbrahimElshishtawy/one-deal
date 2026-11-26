import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/badges/verification_badges.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/requirements/document_requirements_widgets.dart';

// ============================================================================
// SCREEN 08: VERIFICATION TRACKING CENTER WIDGETS
// ============================================================================

class VerificationTrackingHeader extends StatelessWidget {
  const VerificationTrackingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Text(
      s.trackingTitle,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: DealOneTokens.textPrimaryOf(context),
      ),
    );
  }
}

class VerificationStatusCard extends StatelessWidget {
  final VerificationStatus status;
  final SellerType? sellerType;
  final VerificationTier verificationTier;
  final VerificationBadgeEntity? badge;

  const VerificationStatusCard({
    super.key,
    required this.status,
    required this.verificationTier,
    this.sellerType,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isDark = AppColors.isDark(context);

    final (Color accent, Color bg, IconData icon) = switch (status) {
      VerificationStatus.approved => (
          AppColors.successOf(context),
          isDark ? AppColors.darkSuccessTint : AppColors.successTint,
          Icons.verified_rounded,
        ),
      VerificationStatus.rejected || VerificationStatus.suspended => (
          AppColors.errorOf(context),
          isDark ? AppColors.darkErrorTint : AppColors.errorTint,
          Icons.gpp_bad_outlined,
        ),
      VerificationStatus.needsChanges || VerificationStatus.expired => (
          AppColors.warningOf(context),
          isDark ? AppColors.darkWarningTint : AppColors.warningTint,
          Icons.edit_note_rounded,
        ),
      VerificationStatus.pending || VerificationStatus.underReview => (
          AppColors.infoOf(context),
          isDark ? AppColors.darkInfoTint : AppColors.infoTint,
          Icons.hourglass_top_rounded,
        ),
      VerificationStatus.draft || VerificationStatus.notSubmitted => (
          DealOneTokens.textSecondaryOf(context),
          DealOneTokens.softTileBgOf(context),
          Icons.assignment_outlined,
        ),
    };

    return VerificationSectionCard(
      color: bg,
      borderColor: accent.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: AppRadii.md,
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.statusLabel(status),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                if (sellerType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.sellerTypeLabel(sellerType!),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                ],
                if (status.isApproved && verificationTier.isVerified) ...[
                  const SizedBox(height: 8),
                  VerificationBadge(
                    verificationStatus: status,
                    verificationTier: verificationTier,
                    badge: badge,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationTimelineItem extends StatelessWidget {
  final VerificationHistoryItemEntity item;
  final bool isLast;

  const VerificationTimelineItem({
    super.key,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final dt = item.createdAt;
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.isDark(context)
                      ? DealOneTokens.amberWarm
                      : DealOneTokens.navy,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: DealOneTokens.cardBorderOf(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.statusLabel(item.newStatus),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ],
                  ),
                  if (item.reason != null && item.reason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.reason!,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationTimeline extends StatelessWidget {
  final List<VerificationHistoryItemEntity> items;

  const VerificationTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.timelineTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < items.length; i++)
            VerificationTimelineItem(
              item: items[i],
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class VerificationSubmittedInfo extends StatelessWidget {
  final SellerApplicationEntity application;

  const VerificationSubmittedInfo({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final submitted = application.submittedAt;
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (application.businessName != null)
            Text(
              application.businessName!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
          if (submitted != null) ...[
            const SizedBox(height: 4),
            Text(
              '${s.submissionDateLabel}: ${submitted.year}-${submitted.month.toString().padLeft(2, '0')}-${submitted.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12.5,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VerificationRejectionReasonCard extends StatelessWidget {
  final String reason;

  const VerificationRejectionReasonCard({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationNoticeBanner(
      title: s.rejectionReasonTitle,
      message: reason,
      tone: VerificationNoticeTone.error,
      icon: Icons.cancel_outlined,
    );
  }
}

class VerificationCorrectionNotice extends StatelessWidget {
  final String reason;
  final List<String> affectedFields;

  const VerificationCorrectionNotice({
    super.key,
    required this.reason,
    this.affectedFields = const [],
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final detail = affectedFields.isEmpty
        ? reason
        : '$reason\n(${affectedFields.join(', ')})';
    return VerificationNoticeBanner(
      title: s.correctionNoticeTitle,
      message: detail,
      tone: VerificationNoticeTone.warning,
      icon: Icons.edit_note_rounded,
    );
  }
}

class VerificationResubmitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VerificationResubmitButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return ContinueButton(
      label: s.resubmitBtn,
      icon: Icons.refresh_rounded,
      onPressed: onPressed,
    );
  }
}

class VerificationApprovedCard extends StatelessWidget {
  final VerificationStatusSnapshot snapshot;
  final VoidCallback? onUpgradeTap;

  const VerificationApprovedCard({
    super.key,
    required this.snapshot,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      borderColor: AppColors.successOf(context).withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppColors.successOf(context),
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  s.approvedCardTitle,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          VerificationBadge(
            verificationStatus: snapshot.sellerStatus,
            verificationTier: snapshot.verificationTier,
            badge: snapshot.activeBadge,
          ),
          if (snapshot.capabilities.canUpgradeToBusiness &&
              onUpgradeTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            ContinueButton(
              label: s.businessUpgradeTitle,
              icon: Icons.business_rounded,
              onPressed: onUpgradeTap,
            ),
          ],
        ],
      ),
    );
  }
}

class VerificationSuspendedCard extends StatelessWidget {
  final String? reason;

  const VerificationSuspendedCard({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationNoticeBanner(
      title: s.suspendedCardTitle,
      message: (reason != null && reason!.trim().isNotEmpty)
          ? '${s.suspendedCardBody}\n$reason'
          : s.suspendedCardBody,
      tone: VerificationNoticeTone.error,
      icon: Icons.block_rounded,
    );
  }
}

class ContactSupportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ContactSupportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return SizedBox(
      width: double.infinity,
      height: DealOneTokens.compactButtonMinHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.support_agent_rounded, size: 18),
        label: Text(s.contactSupportLabel),
      ),
    );
  }
}

// ============================================================================
// SCREEN 10: INDIVIDUAL-TO-BUSINESS UPGRADE WIDGETS
// ============================================================================

class BusinessUpgradeHeader extends StatelessWidget {
  const BusinessUpgradeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.businessUpgradeTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.businessUpgradeSubtitle,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}

class CurrentVerificationTierCard extends StatelessWidget {
  final VerificationTier tier;
  final VerificationBadgeEntity? badge;

  const CurrentVerificationTierCard({
    super.key,
    required this.tier,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s.currentTierLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          VerificationBadge(
            verificationStatus: tier.isVerified
                ? VerificationStatus.approved
                : VerificationStatus.notSubmitted,
            verificationTier: tier,
            badge: badge,
          ),
        ],
      ),
    );
  }
}

class UpgradeBenefitsSection extends StatelessWidget {
  const UpgradeBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationNoticeBanner(
      title: s.upgradeBenefitsTitle,
      message: s.upgradePreservationNote,
      tone: VerificationNoticeTone.info,
      icon: Icons.verified_outlined,
    );
  }
}

class UpgradeRequirementsList extends StatelessWidget {
  final List<SellerVerificationRequirementEntity> requirements;
  final Set<String> uploadedTypes;

  const UpgradeRequirementsList({
    super.key,
    required this.requirements,
    this.uploadedTypes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return DocumentRequirementsList(
      requirements: requirements,
      uploadedDocumentTypes: uploadedTypes,
    );
  }
}

class UpgradeStatusCard extends StatelessWidget {
  final SellerApplicationEntity application;

  const UpgradeStatusCard({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return VerificationStatusCard(
      status: application.status,
      sellerType: SellerType.business,
      verificationTier:
          application.derivedVerificationTier ?? VerificationTier.none,
    );
  }
}

class UpgradeSubmissionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const UpgradeSubmissionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ContinueButton(
      label: label,
      icon: Icons.upgrade_rounded,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}
