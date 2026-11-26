import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/review/review_and_success_widgets.dart';

/// SCREEN 06 — Review Before Submission
class VerificationReviewPage extends ConsumerWidget {
  const VerificationReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final typeState = ref.watch(sellerTypeSelectionProvider);
    final infoState = ref.watch(sellerInformationProvider);
    final reqState = ref.watch(verificationRequirementsProvider);
    final uploadState = ref.watch(documentUploadProvider);
    final subState = ref.watch(verificationSubmissionProvider);
    final subNotifier = ref.read(verificationSubmissionProvider.notifier);

    final docs = uploadState.confirmedDocuments;
    final missingDocs = SellerVerificationValidators.findMissingRequiredDocuments(
      requirements: reqState.requirements,
      uploadedDocuments: docs,
    );

    final isBusiness = typeState.selectedType == SellerType.business;
    final summaryFields = <String, String>{
      if (isBusiness) s.businessNameLabel: infoState.businessName,
      if (!isBusiness) s.fullNameLabel: infoState.fullName,
      if (isBusiness)
        s.commercialRegisterLabel: infoState.commercialRegisterNumber,
      if (isBusiness && infoState.contactPersonName.isNotEmpty)
        s.contactPersonLabel: infoState.contactPersonName,
      if (infoState.contactPhone.isNotEmpty)
        s.phoneLabel: infoState.contactPhone,
      if (infoState.contactEmail.isNotEmpty)
        s.emailLabel: infoState.contactEmail,
      if (infoState.address.isNotEmpty) s.addressLabel: infoState.address,
    };

    final existingStatus =
        infoState.savedApplication?.status ?? VerificationStatus.draft;
    final isResubmission = existingStatus == VerificationStatus.rejected ||
        existingStatus == VerificationStatus.needsChanges ||
        existingStatus == VerificationStatus.expired;

    final canSubmit = missingDocs.isEmpty &&
        subState.isConfirmed &&
        !subState.isSubmitting &&
        !uploadState.hasAnyUploading;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.reviewTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerificationStepProgress(currentStep: 5, totalSteps: 5),
                  const SizedBox(height: AppSpacing.lg),
                  const VerificationReviewHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  if (missingDocs.isNotEmpty) ...[
                    VerificationNoticeBanner(
                      title: s.requiredTag,
                      message: s.missingDocsWarning,
                      tone: VerificationNoticeTone.warning,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (subState.failure != null) ...[
                    FormValidationMessage(
                      message: subState.failure!.userFriendlyMessage,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  SellerTypeSummaryCard(sellerType: typeState.selectedType),
                  const SizedBox(height: AppSpacing.md),
                  SellerInformationSummary(
                    fields: summaryFields,
                    onEdit: () =>
                        context.push(RouteNames.sellerVerificationInfo),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  UploadedDocumentsSummary(
                    requirements: reqState.requirements,
                    documents: docs,
                    onEdit: () =>
                        context.push(RouteNames.sellerVerificationUpload),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SubmissionConfirmationCheckbox(
                    value: subState.isConfirmed,
                    onChanged: subNotifier.toggleConfirmation,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SubmitVerificationButton(
                    isLoading: subState.isSubmitting,
                    onPressed: canSubmit
                        ? () async {
                            final submitted = await subNotifier.submit(
                              isResubmission: isResubmission,
                            );
                            if (submitted != null && context.mounted) {
                              ref.invalidate(sellerVerificationBadgeProvider);
                              context.go(RouteNames.sellerVerificationSuccess);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
