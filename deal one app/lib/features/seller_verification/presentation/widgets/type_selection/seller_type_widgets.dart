import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

class SellerTypeSelectionHeader extends StatelessWidget {
  const SellerTypeSelectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.selectTypeTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.selectTypeSubtitle,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}

class SellerTypeIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const SellerTypeIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isSelected
        ? (isDark ? DealOneTokens.amberWarm : DealOneTokens.navy)
        : DealOneTokens.softTileBgOf(context);
    final fg = isSelected
        ? (isDark ? AppColors.darkOnPrimary : Colors.white)
        : DealOneTokens.textPrimaryOf(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.md),
      child: Icon(icon, color: fg, size: 24),
    );
  }
}

class SellerTypeDescription extends StatelessWidget {
  final String title;
  final String description;
  final String badgePreview;

  const SellerTypeDescription({
    super.key,
    required this.title,
    required this.description,
    required this.badgePreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: DealOneTokens.softTileBgOf(context),
            borderRadius: AppRadii.full,
          ),
          child: Text(
            badgePreview,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ),
      ],
    );
  }
}

class SellerTypeSelectionIndicator extends StatelessWidget {
  final bool isSelected;

  const SellerTypeSelectionIndicator({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.isDark(context)
        ? DealOneTokens.amberWarm
        : DealOneTokens.navy;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? activeColor : Colors.transparent,
        border: Border.all(
          color: isSelected ? activeColor : DealOneTokens.cardBorderOf(context),
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check_rounded,
              size: 15,
              color: AppColors.isDark(context)
                  ? AppColors.darkOnPrimary
                  : Colors.white,
            )
          : null,
    );
  }
}

class SellerTypeCard extends StatelessWidget {
  final SellerType sellerType;
  final IconData icon;
  final String title;
  final String description;
  final String badgePreview;
  final bool isSelected;
  final VoidCallback onTap;

  const SellerTypeCard({
    super.key,
    required this.sellerType,
    required this.icon,
    required this.title,
    required this.description,
    required this.badgePreview,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.isDark(context)
        ? DealOneTokens.amberWarm
        : DealOneTokens.navy;

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: DealOneTokens.cardSurfaceOf(context),
            borderRadius: AppRadii.lg,
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : DealOneTokens.cardBorderOf(context),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: DealOneTokens.cardShadow(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SellerTypeIcon(icon: icon, isSelected: isSelected),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SellerTypeDescription(
                  title: title,
                  description: description,
                  badgePreview: badgePreview,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SellerTypeSelectionIndicator(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class IndividualSellerCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const IndividualSellerCard({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return SellerTypeCard(
      key: const Key('seller_type_card_individual'),
      sellerType: SellerType.individual,
      icon: Icons.person_outline_rounded,
      title: s.individualTitle,
      description: s.individualDesc,
      badgePreview: s.identityVerifiedBadge,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}

class BusinessSellerCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const BusinessSellerCard({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return SellerTypeCard(
      key: const Key('seller_type_card_business'),
      sellerType: SellerType.business,
      icon: Icons.business_rounded,
      title: s.businessTitle,
      description: s.businessDesc,
      badgePreview: s.businessVerifiedBadge,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
