import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/info_form/seller_info_form_widgets.dart';

/// SCREEN 03 — Seller Information Form (Dynamic based on sellerType)
class SellerInformationFormPage extends ConsumerWidget {
  const SellerInformationFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SellerVerificationStrings.of(context);
    final typeState = ref.watch(sellerTypeSelectionProvider);
    final formState = ref.watch(sellerInformationProvider);
    final formNotifier = ref.read(sellerInformationProvider.notifier);
    final onboardingState = ref.watch(sellerOnboardingProvider);
    final govAsync = ref.watch(governoratesProvider);

    final isBusiness = typeState.selectedType == SellerType.business;
    final governorates = govAsync.valueOrNull ?? const <GovernorateEntity>[];
    final selectedGov = governorates
        .where((g) => g.id == formState.governorateId)
        .firstOrNull;
    final cities = selectedGov?.cities ?? const <CityEntity>[];

    final existingApp =
        formState.savedApplication ?? onboardingState.snapshot?.application;
    final hasExistingDraft =
        existingApp != null && existingApp.status.isEditable;

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      appBar: VerificationAppBar(title: s.sellerInfoTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VerificationStepProgress(currentStep: 2, totalSteps: 5),
                  const SizedBox(height: AppSpacing.lg),
                  SellerInformationHeader(sellerType: typeState.selectedType),
                  const SizedBox(height: AppSpacing.lg),
                  if (formState.failure != null) ...[
                    FormValidationMessage(
                      message: formState.failure!.userFriendlyMessage,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  VerificationSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isBusiness) ...[
                          BusinessNameField(
                            value: formState.businessName,
                            errorText: formState.fieldErrors['businessName'],
                            onChanged: (v) =>
                                formNotifier.updateField(businessName: v),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<BusinessAccountType>(
                            initialValue: typeState.selectedBusinessType ==
                                    BusinessAccountType.individual
                                ? BusinessAccountType.company
                                : typeState.selectedBusinessType,
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
                                    child: Text(s.businessEntityTypeLabel(t)),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(sellerTypeSelectionProvider.notifier)
                                    .selectBusinessType(v);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CommercialRegisterField(
                            value: formState.commercialRegisterNumber,
                            errorText: formState
                                .fieldErrors['commercialRegisterNumber'],
                            onChanged: (v) => formNotifier.updateField(
                              commercialRegisterNumber: v,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TaxIdField(
                            value: formState.taxIdNumber,
                            errorText: formState.fieldErrors['taxIdNumber'],
                            onChanged: (v) =>
                                formNotifier.updateField(taxIdNumber: v),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ContactPersonField(
                            value: formState.contactPersonName,
                            errorText: formState
                                .fieldErrors['authorizedRepresentativeName'],
                            onChanged: (v) => formNotifier.updateField(
                              contactPersonName: v,
                            ),
                          ),
                        ] else ...[
                          SellerNameField(
                            value: formState.fullName,
                            errorText: formState.fieldErrors['fullName'] ??
                                formState.fieldErrors['businessName'],
                            onChanged: (v) =>
                                formNotifier.updateField(fullName: v),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          NationalIdField(
                            value: formState.nationalIdNumber,
                            errorText:
                                formState.fieldErrors['nationalIdNumber'],
                            onChanged: (v) =>
                                formNotifier.updateField(nationalIdNumber: v),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        SellerPhoneField(
                          value: formState.contactPhone,
                          errorText: formState.fieldErrors['contactPhone'],
                          onChanged: (v) =>
                              formNotifier.updateField(contactPhone: v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SellerEmailField(
                          value: formState.contactEmail,
                          errorText: formState.fieldErrors['contactEmail'],
                          onChanged: (v) =>
                              formNotifier.updateField(contactEmail: v),
                        ),
                        if (governorates.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          GovernorateSelector(
                            governorates: governorates,
                            selectedGovernorateId: formState.governorateId,
                            onChanged: (govId) => formNotifier.updateField(
                              governorateId: govId,
                              clearCityId: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CitySelector(
                            cities: cities,
                            selectedCityId: formState.cityId,
                            onChanged: (cityId) =>
                                formNotifier.updateField(cityId: cityId),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        SellerAddressField(
                          value: formState.address,
                          errorText: formState.fieldErrors['address'],
                          onChanged: (v) =>
                              formNotifier.updateField(address: v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BusinessActivitySelector(
                          selectedSections: formState.marketplaceSections,
                          onToggle: formNotifier.toggleSection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ContinueButton(
                    label: s.continueLabel,
                    isLoading: formState.isSaving,
                    onPressed: () async {
                      final saved = await formNotifier.saveToBackend(
                        sellerType: typeState.selectedType,
                        businessType: typeState.selectedBusinessType,
                        hasExistingDraft: hasExistingDraft,
                        isArabic: s.isArabic,
                      );
                      if (saved != null && context.mounted) {
                        ref
                            .read(documentUploadProvider.notifier)
                            .hydrateExistingDocuments(saved.documents);
                        await ref
                            .read(verificationRequirementsProvider.notifier)
                            .load(
                              sellerType: saved.sellerType,
                              marketplaceSections: saved.marketplaceSections,
                              forceRefresh: true,
                            );
                        if (context.mounted) {
                          context.push(RouteNames.sellerVerificationRequirements);
                        }
                      }
                    },
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
