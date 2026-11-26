import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/requirements/document_requirements_widgets.dart';

class VerificationReviewHeader extends StatelessWidget {
  const VerificationReviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.reviewTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.reviewSubtitle,
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

class SellerTypeSummaryCard extends StatelessWidget {
  final SellerType sellerType;

  const SellerTypeSummaryCard({super.key, required this.sellerType});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            sellerType == SellerType.business
                ? Icons.business_rounded
                : Icons.person_outline_rounded,
            color: DealOneTokens.textPrimaryOf(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.accountTypeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
                Text(
                  s.sellerTypeLabel(sellerType),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
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

class EditInformationButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EditInformationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: Text(s.editInfoBtn),
    );
  }
}

class EditDocumentsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const EditDocumentsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file_outlined, size: 16),
      label: Text(s.editDocsBtn),
    );
  }
}

class SellerInformationSummary extends StatelessWidget {
  final Map<String, String> fields;
  final VoidCallback onEdit;

  const SellerInformationSummary({
    super.key,
    required this.fields,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.sellerInfoSection,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              EditInformationButton(onPressed: onEdit),
            ],
          ),
          const Divider(height: 16),
          ...fields.entries.where((e) => e.value.trim().isNotEmpty).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: DealOneTokens.textSecondaryOf(context),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class ReviewDocumentItem extends StatelessWidget {
  final SellerVerificationRequirementEntity requirement;
  final SellerDocumentEntity? uploadedDoc;

  const ReviewDocumentItem({
    super.key,
    required this.requirement,
    this.uploadedDoc,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isPresent = uploadedDoc != null && uploadedDoc!.status.isAcceptedOrUploaded;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isPresent
                ? Icons.check_circle_rounded
                : requirement.isRequired
                    ? Icons.cancel_outlined
                    : Icons.radio_button_unchecked_rounded,
            size: 19,
            color: isPresent
                ? AppColors.successOf(context)
                : requirement.isRequired
                    ? AppColors.errorOf(context)
                    : AppColors.textMutedOf(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.localizedName(isArabic: s.isArabic),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                if (uploadedDoc != null)
                  Text(
                    uploadedDoc!.originalFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
              ],
            ),
          ),
          requirement.isRequired
              ? const RequiredDocumentBadge()
              : const OptionalDocumentBadge(),
        ],
      ),
    );
  }
}

class UploadedDocumentsSummary extends StatelessWidget {
  final List<SellerVerificationRequirementEntity> requirements;
  final List<SellerDocumentEntity> documents;
  final VoidCallback onEdit;

  const UploadedDocumentsSummary({
    super.key,
    required this.requirements,
    required this.documents,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.uploadedDocsSection,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              EditDocumentsButton(onPressed: onEdit),
            ],
          ),
          const Divider(height: 16),
          ...requirements.map((req) {
            SellerDocumentEntity? doc;
            for (final d in documents) {
              if (d.documentType == req.documentType && d.isCurrent) {
                doc = d;
                break;
              }
            }
            return ReviewDocumentItem(requirement: req, uploadedDoc: doc);
          }),
        ],
      ),
    );
  }
}

class SubmissionConfirmationCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SubmissionConfirmationCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        s.confirmationCheckboxText,
        style: TextStyle(
          fontSize: 12.5,
          height: 1.4,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
    );
  }
}

class SubmitVerificationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const SubmitVerificationButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return ContinueButton(
      label: s.submitVerificationBtn,
      icon: Icons.send_rounded,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }
}

// ============================================================================
// SCREEN 07: SUBMISSION SUCCESS WIDGETS
// ============================================================================

class VerificationSuccessIcon extends StatelessWidget {
  const VerificationSuccessIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final green = AppColors.successOf(context);
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.darkSuccessTint
            : AppColors.successTint,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle_rounded, color: green, size: 52),
    );
  }
}

class VerificationSuccessHeader extends StatelessWidget {
  const VerificationSuccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return Column(
      children: [
        Text(
          s.successTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.successSubtitle,
          textAlign: TextAlign.center,
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

class ApplicationReferenceCard extends StatelessWidget {
  final String referenceId;

  const ApplicationReferenceCard({super.key, required this.referenceId});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s.referenceNumberLabel,
            style: TextStyle(
              fontSize: 13,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          SelectableText(
            referenceId.length > 12
                ? referenceId.substring(0, 12).toUpperCase()
                : referenceId.toUpperCase(),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class SubmissionDateCard extends StatelessWidget {
  final DateTime submittedAt;

  const SubmissionDateCard({super.key, required this.submittedAt});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final formatted =
        '${submittedAt.year}-${submittedAt.month.toString().padLeft(2, '0')}-${submittedAt.day.toString().padLeft(2, '0')}';
    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s.submissionDateLabel,
            style: TextStyle(
              fontSize: 13,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class PendingStatusBadge extends StatelessWidget {
  const PendingStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final amber = AppColors.warningOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.darkWarningTint
            : AppColors.warningTint,
        borderRadius: AppRadii.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top_rounded, size: 15, color: amber),
          const SizedBox(width: 5),
          Text(
            s.statusLabel(VerificationStatus.pending),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: amber,
            ),
          ),
        ],
      ),
    );
  }
}

class TrackApplicationButton extends StatelessWidget {
  final VoidCallback onPressed;
  const TrackApplicationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return ContinueButton(
      label: s.trackApplicationBtn,
      icon: Icons.timeline_rounded,
      onPressed: onPressed,
    );
  }
}

class ReturnHomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ReturnHomeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return SizedBox(
      width: double.infinity,
      height: DealOneTokens.buttonMinHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
        child: Text(
          s.returnHomeLabel,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
