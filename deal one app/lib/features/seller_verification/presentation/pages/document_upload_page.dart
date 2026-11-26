import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/document_upload/document_upload_widgets.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/requirements/document_requirements_widgets.dart';

/// SCREEN 05 — Document Upload
class DocumentUploadPage extends ConsumerWidget {
  const DocumentUploadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final reqState = ref.watch(verificationRequirementsProvider);
    final uploadState = ref.watch(documentUploadProvider);
    final uploadNotifier = ref.read(documentUploadProvider.notifier);

    final missingRequired =
        SellerVerificationValidators.findMissingRequiredDocuments(
      requirements: reqState.requirements,
      uploadedDocuments: uploadState.confirmedDocuments,
    );
    final uploadedRequiredCount =
        reqState.requiredDocs.length - missingRequired.length;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.uploadTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerificationStepProgress(currentStep: 4, totalSteps: 5),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.uploadSubtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DocumentUploadProgress(
                    uploadedRequiredCount: uploadedRequiredCount,
                    totalRequiredCount: reqState.requiredDocs.length,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...reqState.requirements.map((req) {
                    final slot = uploadState.slotFor(req.documentType);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: DocumentUploadCard(
                        key: Key('doc_upload_card_${req.documentType}'),
                        requirement: req,
                        itemState: slot,
                        onPickSource: (source) => uploadNotifier.pickAndUpload(
                          requirement: req,
                          source: source,
                          isArabic: s.isArabic,
                          replaceDocumentId: slot.confirmedDocument?.id,
                        ),
                        onRetry: () => uploadNotifier.retryUpload(
                          requirement: req,
                          isArabic: s.isArabic,
                        ),
                        onRemove: () =>
                            uploadNotifier.removeDocument(req.documentType),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  ContinueButton(
                    label: s.continueLabel,
                    icon: Icons.fact_check_outlined,
                    onPressed: uploadState.hasAnyUploading
                        ? null
                        : () =>
                            context.push(RouteNames.sellerVerificationReview),
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
