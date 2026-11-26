import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/document_upload/document_upload_widgets.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/info_form/seller_info_form_widgets.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/tracking/tracking_and_upgrade_widgets.dart';

/// SCREEN 10 — Individual to Business Verification Upgrade
class BusinessUpgradePage extends ConsumerStatefulWidget {
  const BusinessUpgradePage({super.key});

  @override
  ConsumerState<BusinessUpgradePage> createState() =>
      _BusinessUpgradePageState();
}

class _BusinessUpgradePageState extends ConsumerState<BusinessUpgradePage> {
  String _businessName = '';
  String _commercialRegister = '';
  String _taxId = '';
  String _contactPerson = '';
  String _address = '';
  BusinessAccountType _businessType = BusinessAccountType.office;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(businessUpgradeProvider.notifier).load(forceRefresh: true);
      final app = ref.read(businessUpgradeProvider).snapshot?.application;
      if (app != null) {
        ref
            .read(documentUploadProvider.notifier)
            .hydrateExistingDocuments(app.documents);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final state = ref.watch(businessUpgradeProvider);
    final notifier = ref.read(businessUpgradeProvider.notifier);
    final uploadState = ref.watch(documentUploadProvider);
    final uploadNotifier = ref.read(documentUploadProvider.notifier);
    final snapshot = state.snapshot;
    final upgradeApp = snapshot?.application;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.businessUpgradeTitle),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.load(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BusinessUpgradeHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isLoading && snapshot == null)
                      const VerificationLoadingSkeleton(cardCount: 3)
                    else if (state.failure != null && snapshot == null)
                      DealOneErrorStateView(
                        error: state.failure!,
                        onRetry: () => notifier.load(forceRefresh: true),
                      )
                    else if (snapshot != null) ...[
                      CurrentVerificationTierCard(
                        tier: snapshot.currentVerificationTier,
                        badge: snapshot.currentVerificationBadge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (snapshot.currentVerificationTier ==
                          VerificationTier.businessVerified) ...[
                        VerificationNoticeBanner(
                          title: s.businessVerifiedBadge,
                          message: s.alreadyBusinessVerified,
                          tone: VerificationNoticeTone.success,
                        ),
                      ] else ...[
                        const UpgradeBenefitsSection(),
                        const SizedBox(height: AppSpacing.md),
                        if (state.failure != null) ...[
                          FormValidationMessage(
                            message: state.failure!.userFriendlyMessage,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (upgradeApp != null) ...[
                          UpgradeStatusCard(application: upgradeApp),
                          const SizedBox(height: AppSpacing.md),
                          if (upgradeApp.status == VerificationStatus.rejected &&
                              upgradeApp.rejectionReason != null) ...[
                            VerificationRejectionReasonCard(
                              reason: upgradeApp.rejectionReason!,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (upgradeApp.status.isEditable) ...[
                            ...snapshot.businessRequirements.map((req) {
                              final slot =
                                  uploadState.slotFor(req.documentType);
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: DocumentUploadCard(
                                  key: Key(
                                    'upgrade_doc_${req.documentType}',
                                  ),
                                  requirement: req,
                                  itemState: slot,
                                  onPickSource: (source) =>
                                      uploadNotifier.pickAndUpload(
                                    requirement: req,
                                    source: source,
                                    isArabic: s.isArabic,
                                    replaceDocumentId:
                                        slot.confirmedDocument?.id,
                                  ),
                                  onRetry: () => uploadNotifier.retryUpload(
                                    requirement: req,
                                    isArabic: s.isArabic,
                                  ),
                                  onRemove: () => uploadNotifier
                                      .removeDocument(req.documentType),
                                ),
                              );
                            }),
                            const SizedBox(height: AppSpacing.md),
                            Builder(
                              builder: (_) {
                                final missing = SellerVerificationValidators
                                    .findMissingRequiredDocuments(
                                  requirements: snapshot.businessRequirements,
                                  uploadedDocuments:
                                      uploadState.confirmedDocuments,
                                );
                                final isResubmission = upgradeApp.status ==
                                        VerificationStatus.rejected ||
                                    upgradeApp.status ==
                                        VerificationStatus.needsChanges;
                                return UpgradeSubmissionButton(
                                  label: isResubmission
                                      ? s.resubmitBtn
                                      : s.submitUpgradeBtn,
                                  isLoading: state.isSubmitting,
                                  onPressed: missing.isEmpty &&
                                          !uploadState.hasAnyUploading
                                      ? () async {
                                          final res =
                                              await notifier.submitUpgrade(
                                            isResubmission: isResubmission,
                                          );
                                          if (res != null && context.mounted) {
                                            ref.invalidate(
                                              sellerVerificationBadgeProvider,
                                            );
                                            context.go(
                                              RouteNames
                                                  .sellerVerificationTracking,
                                            );
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                          ],
                        ] else if (snapshot.eligibleForUpgrade) ...[
                          UpgradeRequirementsList(
                            requirements: snapshot.businessRequirements,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          VerificationSectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BusinessNameField(
                                  value: _businessName,
                                  errorText: state.fieldErrors['businessName'],
                                  onChanged: (v) => _businessName = v,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                DropdownButtonFormField<BusinessAccountType>(
                                  initialValue: _businessType,
                                  decoration: InputDecoration(
                                    labelText: s.businessTypeLabel,
                                    prefixIcon: const Icon(
                                      Icons.store_mall_directory_outlined,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: DealOneTokens.inputFillOf(context),
                                    border: OutlineInputBorder(
                                      borderRadius: AppRadii.md,
                                    ),
                                  ),
                                  items: const [
                                    BusinessAccountType.company,
                                    BusinessAccountType.office,
                                    BusinessAccountType.store,
                                    BusinessAccountType.factory,
                                  ]
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(
                                            s.businessEntityTypeLabel(t),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _businessType = v);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CommercialRegisterField(
                                  value: _commercialRegister,
                                  errorText: state
                                      .fieldErrors['commercialRegisterNumber'],
                                  onChanged: (v) => _commercialRegister = v,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TaxIdField(
                                  value: _taxId,
                                  onChanged: (v) => _taxId = v,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                ContactPersonField(
                                  value: _contactPerson,
                                  onChanged: (v) => _contactPerson = v,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SellerAddressField(
                                  value: _address,
                                  onChanged: (v) => _address = v,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          UpgradeSubmissionButton(
                            label: s.startUpgradeBtn,
                            isLoading: state.isSubmitting,
                            onPressed: () async {
                              final created = await notifier.startUpgrade(
                                businessName: _businessName,
                                commercialRegisterNumber: _commercialRegister,
                                businessType: _businessType,
                                taxIdNumber: _taxId,
                                authorizedRepresentativeName: _contactPerson,
                                address: _address,
                              );
                              if (created != null) {
                                uploadNotifier.hydrateExistingDocuments(
                                  created.documents,
                                );
                              }
                            },
                          ),
                        ],
                      ],
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
