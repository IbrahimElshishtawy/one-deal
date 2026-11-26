import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/features/accounts/presentation/providers/accounts_providers.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_wizard_notifier.dart';
import 'package:market_space/features/seller_verification/application/providers/seller_verification_providers.dart';
import 'package:market_space/features/seller_verification/domain/algorithms/seller_verification_algorithms.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/business_activity_dropdown_field.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/dashed_document_upload_tile.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/document_upload_source_sheet.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/governorate_city_selector_row.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/partner_account_badge_pill.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/profile_logo_upload_card.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/seller_identity_mode_switcher.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_loading_shimmer.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_primary_cta_button.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_step3_status_view.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_step_header.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_submission_loader_overlay.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_text_input_field.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_trust_banner_card.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_wizard_top_bar.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/whatsapp_availability_checkbox.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// 3-Step Buyer-to-Seller Conversion & Verification Wizard:
/// - Step 1: Real Estate / Seller business & location details (`خطوة 1 من 3`)
/// - Step 2: Identity & Document verification (`خطوة 2 من 3`)
/// - Step 3: Submission confirmation & live verification status (`خطوة 3 من 3`)
class SellerVerificationWizardPage extends ConsumerStatefulWidget {
  const SellerVerificationWizardPage({super.key});

  @override
  ConsumerState<SellerVerificationWizardPage> createState() =>
      _SellerVerificationWizardPageState();
}

class _SellerVerificationWizardPageState
    extends ConsumerState<SellerVerificationWizardPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(sellerVerificationWizardProvider.notifier);
      if (!notifier.skipInitialLoad) {
        notifier.initialize();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleBack(SellerVerificationWizardState wizardState) {
    if (wizardState.isSubmitting) return;
    if (wizardState.currentStep == 2) {
      ref.read(sellerVerificationWizardProvider.notifier).goToStep(1);
      _scrollToTop();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.profile);
    }
  }

  Future<void> _pickLogo(bool isArabic) async {
    final source = await DocumentUploadSourceSheet.show(
      context,
      includePdfOption: false,
    );
    if (source == null || !mounted) return;
    final error = await ref
        .read(sellerVerificationWizardProvider.notifier)
        .pickProfileLogo(source, isArabic: isArabic);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: WizardTheme.danger(context),
        ),
      );
    }
  }

  Future<void> _pickDocument(String documentType, bool isArabic) async {
    final source = await DocumentUploadSourceSheet.show(context);
    if (source == null || !mounted) return;
    final error = await ref
        .read(sellerVerificationWizardProvider.notifier)
        .pickDocumentForSlot(
          documentType: documentType,
          source: source,
          isArabic: isArabic,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: WizardTheme.danger(context),
        ),
      );
    }
  }

  Future<void> _submitApplication(bool isArabic) async {
    final ok = await ref
        .read(sellerVerificationWizardProvider.notifier)
        .submitForReview(isArabic: isArabic);
    if (ok && mounted) {
      ref.invalidate(sellerVerificationBadgeProvider);
      ref.invalidate(myAccountsProvider);
      _scrollToTop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final wizardState = ref.watch(sellerVerificationWizardProvider);
    final notifier = ref.read(sellerVerificationWizardProvider.notifier);
    final govAsync = ref.watch(governoratesProvider);

    final governorates = govAsync.valueOrNull ?? const <GovernorateEntity>[];
    final showLoaderOverlay = wizardState.isSubmitting ||
        wizardState.submissionStage == WizardSubmissionStage.failed;

    return PopScope(
      canPop: wizardState.currentStep != 2 && !wizardState.isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !wizardState.isSubmitting) {
          _handleBack(wizardState);
        }
      },
      child: Scaffold(
        backgroundColor: WizardTheme.pageBg(context),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  VerificationWizardTopBar(
                    currentStep: wizardState.currentStep,
                    totalSteps: 3,
                    onBack: () => _handleBack(wizardState),
                  ),
                  Expanded(
                    child: wizardState.isInitialLoading
                        ? const VerificationLoadingShimmer()
                        : wizardState.initialFailure != null &&
                                wizardState.statusSnapshot == null
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: DealOneErrorStateView(
                                  error: wizardState.initialFailure!,
                                  onRetry: () =>
                                      notifier.initialize(forceRefresh: true),
                                ),
                              )
                            : SingleChildScrollView(
                                controller: _scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 28),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 560),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 240),
                                      child: switch (wizardState.currentStep) {
                                        1 => _buildStep1(
                                            context,
                                            isArabic: isArabic,
                                            state: wizardState,
                                            notifier: notifier,
                                            govAsync: govAsync,
                                            governorates: governorates,
                                          ),
                                        2 => _buildStep2(
                                            context,
                                            isArabic: isArabic,
                                            state: wizardState,
                                            notifier: notifier,
                                          ),
                                        _ => KeyedSubtree(
                                            key: const ValueKey('wizard_step_3'),
                                            child: VerificationStep3StatusView(
                                              snapshot:
                                                  wizardState.statusSnapshot,
                                              application: wizardState
                                                      .submittedApplication ??
                                                  wizardState.statusSnapshot
                                                      ?.application,
                                              officeName:
                                                  wizardState.officeName,
                                              activityCode:
                                                  wizardState.activityCode,
                                              identityMode:
                                                  wizardState.identityMode,
                                              onTrackTap: () => context.push(
                                                RouteNames
                                                    .sellerVerificationTracking,
                                              ),
                                              onDevApproveTap: () async {
                                                final ok = await notifier
                                                    .devApproveForTesting();
                                                if (ok && context.mounted) {
                                                  ref.invalidate(
                                                    sellerVerificationBadgeProvider,
                                                  );
                                                  ref.invalidate(
                                                    myAccountsProvider,
                                                  );
                                                  ref.invalidate(
                                                    activeAccountProvider,
                                                  );
                                                  _scrollToTop();
                                                } else if (context.mounted) {
                                                  final err = ref
                                                      .read(
                                                        sellerVerificationWizardProvider,
                                                      )
                                                      .submissionErrorMessage;
                                                  if (err != null) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(err),
                                                        backgroundColor:
                                                            WizardTheme.danger(
                                                          context,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              isDevApproving:
                                                  wizardState.isDevApproving,
                                              onEditResubmitTap: () {
                                                notifier
                                                    .startEditingFromStatus();
                                                _scrollToTop();
                                              },
                                              onReturnHomeTap: () =>
                                                  context.go(RouteNames.root),
                                            ),
                                          ),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
            if (showLoaderOverlay)
              VerificationSubmissionLoaderOverlay(
                stage: wizardState.submissionStage,
                progress: wizardState.overallUploadProgress,
                errorMessage: wizardState.submissionErrorMessage,
                onRetry: () => _submitApplication(isArabic),
                onDismissError: notifier.dismissSubmissionFailure,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(
    BuildContext context, {
    required bool isArabic,
    required SellerVerificationWizardState state,
    required SellerVerificationWizardNotifier notifier,
    required AsyncValue<List<GovernorateEntity>> govAsync,
    required List<GovernorateEntity> governorates,
  }) {
    return Column(
      key: const ValueKey('wizard_step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PartnerAccountBadgePill(),
        const SizedBox(height: 14),
        VerificationStepHeader(
          title: isArabic
              ? 'بيع العقارات يبدأ من هنا'
              : 'Selling Properties Starts Here',
          subtitle: isArabic
              ? 'أدخل بيانات مكتبك العقاري لتتمكن من إضافة وتصفح الإعلانات وتلقي طلبات المعاينة.'
              : 'Enter your office or seller details to publish listings and receive viewing requests.',
        ),
        const SizedBox(height: 22),
        VerificationTextInputField(
          fieldKey: const Key('wizard_office_name_input'),
          label: isArabic
              ? 'اسم المكتب / الشركة العقارية'
              : 'Office / Company Name',
          hint: isArabic
              ? 'مثال: القمة للاستثمار العقاري'
              : 'e.g., Al-Qemma Real Estate Investment',
          value: state.officeName,
          errorText: state.fieldErrors['officeName'],
          onChanged: notifier.setOfficeName,
        ),
        const SizedBox(height: 16),
        BusinessActivityDropdownField(
          selectedCode: state.activityCode,
          errorText: state.fieldErrors['activityCode'],
          onSelected: notifier.setActivity,
        ),
        const SizedBox(height: 16),
        GovernorateCitySelectorRow(
          governorates: governorates,
          selectedGovernorateId: state.governorateId,
          selectedCityId: state.cityId,
          isLoadingLocations: govAsync.isLoading,
          hasLocationsError: govAsync.hasError,
          onRetryLocations: () => ref.invalidate(governoratesProvider),
          onGovernorateChanged: notifier.setGovernorate,
          onCityChanged: notifier.setCity,
          governorateError: state.fieldErrors['governorateId'],
          cityError: state.fieldErrors['cityId'],
        ),
        const SizedBox(height: 16),
        VerificationTextInputField(
          fieldKey: const Key('wizard_contact_phone_input'),
          label: isArabic ? 'رقم هاتف التواصل' : 'Contact Phone Number',
          hint: '01xxxxxxxxx',
          value: state.contactPhone,
          keyboardType: TextInputType.phone,
          trailingIcon: Icons.phone_in_talk_outlined,
          errorText: state.fieldErrors['contactPhone'],
          onChanged: notifier.setContactPhone,
        ),
        const SizedBox(height: 8),
        WhatsappAvailabilityCheckbox(
          value: state.isWhatsappAvailable,
          onChanged: notifier.toggleWhatsapp,
        ),
        const SizedBox(height: 16),
        VerificationTrustBannerCard(
          title: isArabic ? 'ضمان توثيق الحسابات' : 'Account Verification Assurance',
          body: isArabic
              ? 'تخضع جميع المكاتب العقارية للمراجعة السريعة لضمان موثوقية العروض للعملاء.'
              : 'All seller accounts undergo fast verification review to guarantee trusted offers for buyers.',
        ),
        const SizedBox(height: 22),
        VerificationPrimaryCtaButton(
          key: const Key('wizard_step1_continue_btn'),
          label: isArabic ? 'متابعة' : 'Continue',
          onPressed: () {
            final moved = notifier.advanceFromStep1(
              hasLocationsLoaded: governorates.isNotEmpty,
              isArabic: isArabic,
            );
            if (moved) {
              _scrollToTop();
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context, {
    required bool isArabic,
    required SellerVerificationWizardState state,
    required SellerVerificationWizardNotifier notifier,
  }) {
    final isBusiness = state.identityMode == SellerType.business;
    final nidAnalysis = !isBusiness && state.nationalIdNumber.isNotEmpty
        ? SellerVerificationAlgorithms.analyzeNationalId(
            state.nationalIdNumber,
            isArabic: isArabic,
          )
        : null;

    final primaryPair =
        SellerVerificationAlgorithms.documentPairForMode(state.identityMode);
    final slot1 = state.slotFor(primaryPair.$1);
    final slot2 = state.slotFor(primaryPair.$2);

    return Column(
      key: const ValueKey('wizard_step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationStepHeader(
          title: isArabic
              ? 'توثيق الهوية والبيانات'
              : 'Identity & Data Verification',
          titleIcon: Icons.verified_outlined,
          subtitle: isArabic
              ? 'أكمل بيانات التوثيق لزيادة موثوقية حسابك وإعلاناتك أمام العملاء المستهدفين.'
              : 'Complete verification details to increase your account trust with buyers.',
        ),
        const SizedBox(height: 18),
        SellerIdentityModeSwitcher(
          selectedMode: state.identityMode,
          onChanged: notifier.setIdentityMode,
        ),
        const SizedBox(height: 20),
        ProfileLogoUploadCard(
          localFile: state.profileLogoFile,
          confirmedDocument: state.confirmedLogoDocument,
          onPickTap: () => _pickLogo(isArabic),
          onRemoveTap: notifier.clearProfileLogo,
        ),
        const SizedBox(height: 18),
        if (!isBusiness) ...[
          VerificationTextInputField(
            fieldKey: const Key('wizard_national_id_input'),
            label: isArabic
                ? 'رقم البطاقة الشخصية (الرقم القومي)'
                : 'National ID Number',
            hint: isArabic
                ? 'أدخل الرقم القومي المكون من 14 رقماً'
                : 'Enter 14-digit National ID number',
            value: state.nationalIdNumber,
            keyboardType: TextInputType.number,
            maxLength: 14,
            trailingIcon: Icons.badge_outlined,
            errorText: state.fieldErrors['nationalIdNumber'],
            helperText: isArabic
                ? 'للتحقق من الهوية وضمان موثوقية الحسابات العقارية'
                : 'Used solely for identity verification and seller trust',
            helperStatusText: state.nationalIdNumber.isEmpty
                ? null
                : (nidAnalysis?.isValid == true
                    ? (nidAnalysis!.localizedGovernorate(isArabic) ?? '14/14 ✓')
                    : '${state.nationalIdNumber.length}/14'),
            helperStatusValid: nidAnalysis?.isValid == true,
            onChanged: notifier.setNationalId,
          ),
          const SizedBox(height: 18),
          _buildDocumentsPairHeader(
            context,
            isArabic: isArabic,
            label: isArabic
                ? 'صورة البطاقة الشخصية (الوجه والظهر)'
                : 'National ID Photo (Front & Back)',
            hasError: state.fieldErrors.containsKey('national_id_front') ||
                state.fieldErrors.containsKey('national_id_back'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DashedDocumentUploadTile(
                  tileKey: const Key('wizard_doc_tile_front'),
                  title: isArabic ? 'وجه البطاقة' : 'ID Front',
                  actionHint: isArabic ? '+ اضغط للرفع' : '+ Tap to upload',
                  icon: Icons.contact_page_outlined,
                  slot: slot1,
                  validationError: state.fieldErrors['national_id_front'],
                  onTap: () => _pickDocument('national_id_front', isArabic),
                  onRemove: () =>
                      notifier.removeDocumentSlot('national_id_front'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashedDocumentUploadTile(
                  tileKey: const Key('wizard_doc_tile_back'),
                  title: isArabic ? 'ظهر البطاقة' : 'ID Back',
                  actionHint: isArabic ? '+ اضغط للرفع' : '+ Tap to upload',
                  icon: Icons.credit_card_outlined,
                  slot: slot2,
                  validationError: state.fieldErrors['national_id_back'],
                  onTap: () => _pickDocument('national_id_back', isArabic),
                  onRemove: () =>
                      notifier.removeDocumentSlot('national_id_back'),
                ),
              ),
            ],
          ),
        ] else ...[
          VerificationTextInputField(
            fieldKey: const Key('wizard_commercial_register_input'),
            label: isArabic
                ? 'رقم السجل التجاري'
                : 'Commercial Registration Number',
            hint: isArabic
                ? 'أدخل رقم السجل التجاري للشركة أو المكتب'
                : 'Enter commercial registration number',
            value: state.commercialRegisterNumber,
            trailingIcon: Icons.domain_verification_outlined,
            errorText: state.fieldErrors['commercialRegisterNumber'],
            onChanged: notifier.setCommercialRegister,
          ),
          const SizedBox(height: 14),
          VerificationTextInputField(
            fieldKey: const Key('wizard_tax_id_input'),
            label: isArabic
                ? 'رقم البطاقة الضريبية / التسجيل الضريبي'
                : 'Tax Registration Number',
            hint: isArabic ? 'مثال: 123-456-789' : 'e.g., 123-456-789',
            value: state.taxIdNumber,
            isRequired: false,
            trailingIcon: Icons.receipt_long_outlined,
            onChanged: notifier.setTaxId,
          ),
          const SizedBox(height: 18),
          _buildDocumentsPairHeader(
            context,
            isArabic: isArabic,
            label: isArabic
                ? 'مستندات السجل التجاري والبطاقة الضريبية'
                : 'Commercial Register & Tax Card',
            hasError: state.fieldErrors.containsKey('commercial_register') ||
                state.fieldErrors.containsKey('tax_card'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DashedDocumentUploadTile(
                  tileKey: const Key('wizard_doc_tile_cr'),
                  title: isArabic ? 'السجل التجاري' : 'Commercial Register',
                  actionHint: isArabic ? '+ اضغط للرفع' : '+ Tap to upload',
                  icon: Icons.description_outlined,
                  slot: slot1,
                  validationError: state.fieldErrors['commercial_register'],
                  onTap: () => _pickDocument('commercial_register', isArabic),
                  onRemove: () =>
                      notifier.removeDocumentSlot('commercial_register'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashedDocumentUploadTile(
                  tileKey: const Key('wizard_doc_tile_tax'),
                  title: isArabic ? 'البطاقة الضريبية' : 'Tax Card',
                  actionHint: isArabic ? '+ اضغط للرفع' : '+ Tap to upload',
                  icon: Icons.credit_card_outlined,
                  slot: slot2,
                  validationError: state.fieldErrors['tax_card'],
                  onTap: () => _pickDocument('tax_card', isArabic),
                  onRemove: () => notifier.removeDocumentSlot('tax_card'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        VerificationTextInputField(
          fieldKey: const Key('wizard_bio_input'),
          label: isArabic ? 'نبذة مختصرة' : 'Short Bio',
          hint: isArabic
              ? 'اكتب نبذة موجزة عن خبرتك في التطوير والتسويق العقاري والمناطق الجغرافية التي تغطيها...'
              : 'Write a brief overview of your experience and areas you cover...',
          value: state.shortBio,
          isRequired: false,
          minLines: 4,
          maxLines: 5,
          maxLength: 500,
          onChanged: notifier.setShortBio,
        ),
        const SizedBox(height: 18),
        VerificationTrustBannerCard(
          title: isArabic
              ? 'حماية وضمان الصفقة الأولى'
              : 'Deal One Security & Protection',
          body: isArabic
              ? 'يتم مراجعة المستندات طبقاً للأنظمة العقارية المعتمدة ولا يتم مشاركة بيانات هويتك الشخصية مع أي طرف ثالث.'
              : 'Documents are reviewed under approved verification policies and personal ID data is never shared with third parties.',
        ),
        const SizedBox(height: 22),
        VerificationPrimaryCtaButton(
          key: const Key('wizard_step2_submit_btn'),
          label: isArabic ? 'إرسال للمراجعة' : 'Submit for Review',
          isLoading: state.isSubmitting,
          onPressed: () => _submitApplication(isArabic),
        ),
      ],
    );
  }

  Widget _buildDocumentsPairHeader(
    BuildContext context, {
    required bool isArabic,
    required String label,
    required bool hasError,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: WizardTheme.primaryInk(context),
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: hasError
                  ? WizardTheme.danger(context)
                  : WizardTheme.primaryInk(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
