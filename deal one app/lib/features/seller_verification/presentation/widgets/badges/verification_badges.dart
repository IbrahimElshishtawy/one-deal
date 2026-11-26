import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

/// Displays an Identity Verified badge (`هوية موثقة`).
class IdentityVerifiedBadge extends StatelessWidget {
  final String? labelOverride;
  final bool compact;

  const IdentityVerifiedBadge({
    super.key,
    this.labelOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isDark = AppColors.isDark(context);
    final accent = AppColors.infoOf(context);
    final bg = isDark ? AppColors.darkInfoTint : AppColors.infoTint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.full,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: compact ? 13 : 15,
            color: accent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              labelOverride ?? s.identityVerifiedBadge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a Business Verified badge (`شركة / مكتب موثق`).
class BusinessVerifiedBadge extends StatelessWidget {
  final String? labelOverride;
  final bool compact;

  const BusinessVerifiedBadge({
    super.key,
    this.labelOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isDark = AppColors.isDark(context);
    final accent = AppColors.successOf(context);
    final bg = isDark ? AppColors.darkSuccessTint : AppColors.successTint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.full,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 13 : 15,
            color: accent,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              labelOverride ?? s.businessVerifiedBadge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified VerificationBadge widget.
/// Strictly enforces backend trust rules:
/// - Never renders a badge when status != APPROVED or tier == NONE or badge == null.
/// - Never infers verification from sellerType.
class VerificationBadge extends StatelessWidget {
  final VerificationStatus verificationStatus;
  final VerificationTier verificationTier;
  final VerificationBadgeEntity? badge;
  final bool compact;

  const VerificationBadge({
    super.key,
    required this.verificationStatus,
    required this.verificationTier,
    this.badge,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!verificationStatus.isApproved || !verificationTier.isVerified) {
      return const SizedBox.shrink();
    }

    final isArabic = SellerVerificationStrings.of(context).isArabic;
    final resolvedLabel = isArabic ? badge?.label : null;

    switch (verificationTier) {
      case VerificationTier.businessVerified:
        return BusinessVerifiedBadge(
          labelOverride: resolvedLabel,
          compact: compact,
        );
      case VerificationTier.identityVerified:
        return IdentityVerifiedBadge(
          labelOverride: resolvedLabel,
          compact: compact,
        );
      case VerificationTier.none:
        return const SizedBox.shrink();
    }
  }
}

/// Pill displaying the seller's classification (`INDIVIDUAL`, `BUSINESS`, `SERVICE_PROVIDER`).
class SellerAccountTypeLabel extends StatelessWidget {
  final SellerType sellerType;

  const SellerAccountTypeLabel({super.key, required this.sellerType});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final icon = switch (sellerType) {
      SellerType.business => Icons.business_center_outlined,
      SellerType.serviceProvider => Icons.handyman_outlined,
      SellerType.individual => Icons.person_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DealOneTokens.softTileBgOf(context),
        borderRadius: AppRadii.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DealOneTokens.textPrimaryOf(context)),
          const SizedBox(width: 5),
          Text(
            s.sellerTypeLabel(sellerType),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Verified Seller Header for Seller Profile & Seller Verification Profile Page.
class VerifiedSellerHeader extends StatelessWidget {
  final String displayName;
  final SellerType sellerType;
  final VerificationStatus verificationStatus;
  final VerificationTier verificationTier;
  final VerificationBadgeEntity? badge;

  const VerifiedSellerHeader({
    super.key,
    required this.displayName,
    required this.sellerType,
    required this.verificationStatus,
    required this.verificationTier,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DealOneTokens.cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: DealOneTokens.navy,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SellerAccountTypeLabel(sellerType: sellerType),
                    VerificationBadge(
                      verificationStatus: verificationStatus,
                      verificationTier: verificationTier,
                      badge: badge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card showing current seller verification tier, status, and optional upgrade action.
class SellerVerificationSummary extends StatelessWidget {
  final VerificationStatusSnapshot snapshot;
  final VoidCallback? onTrackTap;
  final VoidCallback? onUpgradeTap;

  const SellerVerificationSummary({
    super.key,
    required this.snapshot,
    this.onTrackTap,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.verificationLevelLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              VerificationBadge(
                verificationStatus: snapshot.sellerStatus,
                verificationTier: snapshot.verificationTier,
                badge: snapshot.activeBadge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${s.statusLabel(snapshot.sellerStatus)}${snapshot.sellerType != null ? ' • ${s.sellerTypeLabel(snapshot.sellerType!)}' : ''}',
            style: TextStyle(
              fontSize: 12.5,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          if (onTrackTap != null ||
              (snapshot.capabilities.canUpgradeToBusiness &&
                  onUpgradeTap != null)) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (onTrackTap != null)
                  OutlinedButton.icon(
                    onPressed: onTrackTap,
                    icon: const Icon(Icons.timeline_rounded, size: 17),
                    label: Text(s.viewApplicationStatusCta),
                  ),
                if (snapshot.capabilities.canUpgradeToBusiness &&
                    onUpgradeTap != null)
                  ElevatedButton.icon(
                    onPressed: onUpgradeTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DealOneTokens.navy,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upgrade_rounded, size: 17),
                    label: Text(s.businessUpgradeTitle),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
