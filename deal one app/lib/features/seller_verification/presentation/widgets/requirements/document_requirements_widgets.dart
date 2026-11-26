import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

class DocumentRequirementsHeader extends StatelessWidget {
  const DocumentRequirementsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.requirementsTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.requirementsSubtitle,
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

class RequiredDocumentBadge extends StatelessWidget {
  const RequiredDocumentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final accent = AppColors.errorOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.errorTintOf(context),
        borderRadius: AppRadii.full,
      ),
      child: Text(
        s.requiredTag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class OptionalDocumentBadge extends StatelessWidget {
  const OptionalDocumentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DealOneTokens.softTileBgOf(context),
        borderRadius: AppRadii.full,
      ),
      child: Text(
        s.optionalTag,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: DealOneTokens.textSecondaryOf(context),
        ),
      ),
    );
  }
}

class DocumentRequirementDescription extends StatelessWidget {
  final SellerVerificationRequirementEntity requirement;

  const DocumentRequirementDescription({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final formats = requirement.acceptedMimeTypes
        .map((m) => m.split('/').last.toUpperCase())
        .join(', ');
    final maxMb = requirement.maxFileSizeMb.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requirement.description != null &&
            requirement.description!.trim().isNotEmpty) ...[
          Text(
            requirement.description!,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          '${s.formatsAcceptedPrefix} $formats • ${s.maxSizePrefix} $maxMb MB',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedOf(context),
          ),
        ),
      ],
    );
  }
}

class DocumentRequirementCard extends StatelessWidget {
  final SellerVerificationRequirementEntity requirement;
  final bool isUploaded;

  const DocumentRequirementCard({
    super.key,
    required this.requirement,
    this.isUploaded = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isUploaded
          ? AppColors.successOf(context).withValues(alpha: 0.45)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUploaded
                  ? (AppColors.isDark(context)
                      ? AppColors.darkSuccessTint
                      : AppColors.successTint)
                  : DealOneTokens.softTileBgOf(context),
              borderRadius: AppRadii.md,
            ),
            child: Icon(
              isUploaded
                  ? Icons.check_circle_rounded
                  : Icons.description_outlined,
              color: isUploaded
                  ? AppColors.successOf(context)
                  : DealOneTokens.textPrimaryOf(context),
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        requirement.localizedName(isArabic: s.isArabic),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    requirement.isRequired
                        ? const RequiredDocumentBadge()
                        : const OptionalDocumentBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                DocumentRequirementDescription(requirement: requirement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentUploadProgress extends StatelessWidget {
  final int uploadedRequiredCount;
  final int totalRequiredCount;

  const DocumentUploadProgress({
    super.key,
    required this.uploadedRequiredCount,
    required this.totalRequiredCount,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final ratio = totalRequiredCount <= 0
        ? 1.0
        : (uploadedRequiredCount / totalRequiredCount).clamp(0.0, 1.0);

    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.requiredTag,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
              Text(
                '$uploadedRequiredCount / $totalRequiredCount',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: DealOneTokens.softTileBgOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio >= 1.0
                    ? AppColors.successOf(context)
                    : DealOneTokens.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentRequirementsList extends StatelessWidget {
  final List<SellerVerificationRequirementEntity> requirements;
  final Set<String> uploadedDocumentTypes;

  const DocumentRequirementsList({
    super.key,
    required this.requirements,
    this.uploadedDocumentTypes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: requirements
          .map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DocumentRequirementCard(
                requirement: req,
                isUploaded: uploadedDocumentTypes.contains(req.documentType),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class DocumentUploadHelpSection extends StatelessWidget {
  const DocumentUploadHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationNoticeBanner(
      title: s.uploadHelpTitle,
      message: s.uploadHelpBody,
      tone: VerificationNoticeTone.info,
      icon: Icons.lightbulb_outline_rounded,
    );
  }
}
