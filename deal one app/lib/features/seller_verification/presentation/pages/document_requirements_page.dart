import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/requirements/document_requirements_widgets.dart';

/// SCREEN 04 — Dynamic Document Requirements
class DocumentRequirementsPage extends ConsumerStatefulWidget {
  const DocumentRequirementsPage({super.key});

  @override
  ConsumerState<DocumentRequirementsPage> createState() =>
      _DocumentRequirementsPageState();
}

class _DocumentRequirementsPageState
    extends ConsumerState<DocumentRequirementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final typeState = ref.read(sellerTypeSelectionProvider);
      final infoState = ref.read(sellerInformationProvider);
      final reqState = ref.read(verificationRequirementsProvider);
      if (reqState.requirements.isEmpty && !reqState.isLoading) {
        ref.read(verificationRequirementsProvider.notifier).load(
              sellerType: typeState.selectedType,
              marketplaceSections: infoState.marketplaceSections,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final reqState = ref.watch(verificationRequirementsProvider);
    final uploadState = ref.watch(documentUploadProvider);
    final typeState = ref.watch(sellerTypeSelectionProvider);
    final infoState = ref.watch(sellerInformationProvider);

    final uploadedTypes = uploadState.confirmedDocuments
        .where((d) => d.status.isAcceptedOrUploaded)
        .map((d) => d.documentType)
        .toSet();
    final requiredDocs = reqState.requiredDocs;
    final uploadedRequiredCount = requiredDocs
        .where((r) => uploadedTypes.contains(r.documentType))
        .length;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.requirementsTitle),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(verificationRequirementsProvider.notifier).load(
                    sellerType: typeState.selectedType,
                    marketplaceSections: infoState.marketplaceSections,
                    forceRefresh: true,
                  ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VerificationStepProgress(
                      currentStep: 3,
                      totalSteps: 5,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const DocumentRequirementsHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    if (reqState.isLoading)
                      const VerificationLoadingSkeleton(cardCount: 3)
                    else if (reqState.failure != null)
                      DealOneErrorStateView(
                        error: reqState.failure!,
                        onRetry: () => ref
                            .read(verificationRequirementsProvider.notifier)
                            .load(
                              sellerType: typeState.selectedType,
                              marketplaceSections:
                                  infoState.marketplaceSections,
                              forceRefresh: true,
                            ),
                      )
                    else ...[
                      DocumentUploadProgress(
                        uploadedRequiredCount: uploadedRequiredCount,
                        totalRequiredCount: requiredDocs.length,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DocumentRequirementsList(
                        requirements: reqState.requirements,
                        uploadedDocumentTypes: uploadedTypes,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const DocumentUploadHelpSection(),
                      const SizedBox(height: AppSpacing.xl),
                      ContinueButton(
                        label: s.uploadTitle,
                        icon: Icons.cloud_upload_outlined,
                        onPressed: () =>
                            context.push(RouteNames.sellerVerificationUpload),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
