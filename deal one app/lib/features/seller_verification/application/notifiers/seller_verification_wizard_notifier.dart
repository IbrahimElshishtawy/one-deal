import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/errors/error_mapper.dart';
import 'package:market_space/features/seller_verification/domain/algorithms/seller_verification_algorithms.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';
import 'package:market_space/features/seller_verification/services/document_upload/document_upload_service.dart';

/// Stages executed by the submission pipeline algorithm.
enum WizardSubmissionStage {
  idle,
  validating,
  savingProfile,
  uploadingDocuments,
  submittingApplication,
  completed,
  failed,
}

/// Slot state for a picked or confirmed verification document in the 3-step wizard.
@immutable
class WizardDocumentSlot {
  final String documentType;
  final PickedDocumentFile? localFile;
  final SellerDocumentEntity? confirmedDocument;
  final double uploadProgress;
  final bool isUploading;
  final String? errorMessage;

  const WizardDocumentSlot({
    required this.documentType,
    this.localFile,
    this.confirmedDocument,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.errorMessage,
  });

  bool get hasFile =>
      localFile != null ||
      (confirmedDocument != null &&
          confirmedDocument!.status.isAcceptedOrUploaded);

  bool get isUploaded =>
      confirmedDocument != null &&
      confirmedDocument!.status.isAcceptedOrUploaded &&
      localFile == null;

  bool get needsUpload => localFile != null;

  WizardDocumentSlot copyWith({
    PickedDocumentFile? localFile,
    bool clearLocalFile = false,
    SellerDocumentEntity? confirmedDocument,
    bool clearConfirmedDocument = false,
    double? uploadProgress,
    bool? isUploading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WizardDocumentSlot(
      documentType: documentType,
      localFile: clearLocalFile ? null : (localFile ?? this.localFile),
      confirmedDocument: clearConfirmedDocument
          ? null
          : (confirmedDocument ?? this.confirmedDocument),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Full immutable state for the 3-step Buyer-to-Seller Verification Wizard.
@immutable
class SellerVerificationWizardState {
  final int currentStep;
  final bool isInitialLoading;
  final AppFailure? initialFailure;
  final VerificationStatusSnapshot? statusSnapshot;

  // Step 1 fields
  final String officeName;
  final String? activityCode;
  final int? governorateId;
  final int? cityId;
  final String contactPhone;
  final bool isWhatsappAvailable;

  // Step 2 fields
  final SellerType identityMode;
  final BusinessAccountType businessAccountType;
  final String nationalIdNumber;
  final String commercialRegisterNumber;
  final String taxIdNumber;
  final String shortBio;
  final PickedDocumentFile? profileLogoFile;
  final SellerDocumentEntity? confirmedLogoDocument;
  final Map<String, WizardDocumentSlot> documentSlots;

  // Validation & multi-stage submission pipeline
  final Map<String, String> fieldErrors;
  final WizardSubmissionStage submissionStage;
  final double overallUploadProgress;
  final String? submissionErrorMessage;
  final SellerApplicationEntity? submittedApplication;

  const SellerVerificationWizardState({
    this.currentStep = 1,
    this.isInitialLoading = true,
    this.initialFailure,
    this.statusSnapshot,
    this.officeName = '',
    this.activityCode,
    this.governorateId,
    this.cityId,
    this.contactPhone = '',
    this.isWhatsappAvailable = false,
    this.identityMode = SellerType.individual,
    this.businessAccountType = BusinessAccountType.office,
    this.nationalIdNumber = '',
    this.commercialRegisterNumber = '',
    this.taxIdNumber = '',
    this.shortBio = '',
    this.profileLogoFile,
    this.confirmedLogoDocument,
    this.documentSlots = const {},
    this.fieldErrors = const {},
    this.submissionStage = WizardSubmissionStage.idle,
    this.overallUploadProgress = 0.0,
    this.submissionErrorMessage,
    this.submittedApplication,
  });

  bool get isSubmitting =>
      submissionStage == WizardSubmissionStage.validating ||
      submissionStage == WizardSubmissionStage.savingProfile ||
      submissionStage == WizardSubmissionStage.uploadingDocuments ||
      submissionStage == WizardSubmissionStage.submittingApplication;

  WizardDocumentSlot slotFor(String documentType) =>
      documentSlots[documentType] ??
      WizardDocumentSlot(documentType: documentType);

  double get readinessProgress {
    final pair = SellerVerificationAlgorithms.documentPairForMode(identityMode);
    return SellerVerificationAlgorithms.computeReadinessProgress(
      currentStep: currentStep,
      officeName: officeName,
      activityCode: activityCode,
      cityId: cityId,
      contactPhone: contactPhone,
      identityMode: identityMode,
      nationalIdNumber: nationalIdNumber,
      commercialRegisterNumber: commercialRegisterNumber,
      hasPrimaryDoc1: slotFor(pair.$1).hasFile,
      hasPrimaryDoc2: slotFor(pair.$2).hasFile,
      applicationStatus: statusSnapshot?.sellerStatus,
    );
  }

  SellerVerificationWizardState copyWith({
    int? currentStep,
    bool? isInitialLoading,
    AppFailure? initialFailure,
    bool clearInitialFailure = false,
    VerificationStatusSnapshot? statusSnapshot,
    String? officeName,
    String? activityCode,
    int? governorateId,
    int? cityId,
    bool clearCityId = false,
    String? contactPhone,
    bool? isWhatsappAvailable,
    SellerType? identityMode,
    BusinessAccountType? businessAccountType,
    String? nationalIdNumber,
    String? commercialRegisterNumber,
    String? taxIdNumber,
    String? shortBio,
    PickedDocumentFile? profileLogoFile,
    bool clearProfileLogo = false,
    SellerDocumentEntity? confirmedLogoDocument,
    Map<String, WizardDocumentSlot>? documentSlots,
    Map<String, String>? fieldErrors,
    WizardSubmissionStage? submissionStage,
    double? overallUploadProgress,
    String? submissionErrorMessage,
    bool clearSubmissionError = false,
    SellerApplicationEntity? submittedApplication,
  }) {
    return SellerVerificationWizardState(
      currentStep: currentStep ?? this.currentStep,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      initialFailure:
          clearInitialFailure ? null : (initialFailure ?? this.initialFailure),
      statusSnapshot: statusSnapshot ?? this.statusSnapshot,
      officeName: officeName ?? this.officeName,
      activityCode: activityCode ?? this.activityCode,
      governorateId: governorateId ?? this.governorateId,
      cityId: clearCityId ? null : (cityId ?? this.cityId),
      contactPhone: contactPhone ?? this.contactPhone,
      isWhatsappAvailable: isWhatsappAvailable ?? this.isWhatsappAvailable,
      identityMode: identityMode ?? this.identityMode,
      businessAccountType: businessAccountType ?? this.businessAccountType,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      commercialRegisterNumber:
          commercialRegisterNumber ?? this.commercialRegisterNumber,
      taxIdNumber: taxIdNumber ?? this.taxIdNumber,
      shortBio: shortBio ?? this.shortBio,
      profileLogoFile:
          clearProfileLogo ? null : (profileLogoFile ?? this.profileLogoFile),
      confirmedLogoDocument:
          confirmedLogoDocument ?? this.confirmedLogoDocument,
      documentSlots: documentSlots ?? this.documentSlots,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      submissionStage: submissionStage ?? this.submissionStage,
      overallUploadProgress:
          overallUploadProgress ?? this.overallUploadProgress,
      submissionErrorMessage: clearSubmissionError
          ? null
          : (submissionErrorMessage ?? this.submissionErrorMessage),
      submittedApplication: submittedApplication ?? this.submittedApplication,
    );
  }
}

/// Coordinates the 3-step Seller Verification Wizard with algorithmic validation,
/// optimistic local previews, presigned private uploads, and backend synchronization.
class SellerVerificationWizardNotifier
    extends StateNotifier<SellerVerificationWizardState> {
  final SellerVerificationRepository repository;
  final DocumentPickerService pickerService;
  final DocumentUploadService uploadService;
  final bool skipInitialLoad;

  SellerVerificationWizardNotifier({
    required this.repository,
    required this.pickerService,
    required this.uploadService,
    this.skipInitialLoad = false,
  }) : super(
          SellerVerificationWizardState(
            isInitialLoading: !skipInitialLoad,
          ),
        );

  /// Loads current verification snapshot from backend and hydrates wizard state.
  Future<void> initialize({bool forceRefresh = true}) async {
    state = state.copyWith(isInitialLoading: true, clearInitialFailure: true);
    try {
      final snapshot = await repository.getMyVerificationStatus(
        forceRefresh: forceRefresh,
      );
      _applySnapshotHydration(snapshot);
    } catch (error) {
      state = state.copyWith(
        isInitialLoading: false,
        initialFailure: ErrorMapper.map(error),
      );
    }
  }

  void _applySnapshotHydration(VerificationStatusSnapshot snapshot) {
    final app = snapshot.application;
    final slots = <String, WizardDocumentSlot>{};
    SellerDocumentEntity? logoDoc;

    if (app != null) {
      for (final doc in app.documents) {
        if (!doc.isCurrent) continue;
        if (doc.documentType == 'additional_document') {
          logoDoc = doc;
          continue;
        }
        slots[doc.documentType] = WizardDocumentSlot(
          documentType: doc.documentType,
          confirmedDocument: doc,
          uploadProgress:
              doc.status.isAcceptedOrUploaded ? 1.0 : 0.0,
          errorMessage: doc.status == SellerDocumentStatus.rejected
              ? doc.rejectionReason
              : null,
        );
      }
    }

    final shouldShowStep3 =
        snapshot.sellerStatus.isInReview ||
        snapshot.sellerStatus.isApproved ||
        snapshot.sellerStatus == VerificationStatus.suspended ||
        snapshot.sellerStatus == VerificationStatus.rejected ||
        snapshot.sellerStatus == VerificationStatus.needsChanges ||
        snapshot.sellerStatus == VerificationStatus.expired;

    final matchedActivity = SellerVerificationAlgorithms.findActivityByCode(
      app?.serviceCategory,
    );

    final rawDesc = app?.businessDescription ?? '';
    final whatsappEnabled = rawDesc.contains('[WhatsApp]') ||
        rawDesc.contains('متاح واتساب');
    final cleanBio = rawDesc
        .replaceAll('\n[WhatsApp]', '')
        .replaceAll('[WhatsApp]', '')
        .replaceAll('\nمتاح واتساب', '')
        .replaceAll('متاح واتساب', '')
        .trim();

    state = state.copyWith(
      isInitialLoading: false,
      statusSnapshot: snapshot,
      currentStep: shouldShowStep3 ? 3 : 1,
      officeName: app?.businessName ?? state.officeName,
      activityCode: matchedActivity?.code ?? state.activityCode,
      cityId: app?.cityId ?? state.cityId,
      contactPhone: app?.contactPhone ?? state.contactPhone,
      isWhatsappAvailable: whatsappEnabled || state.isWhatsappAvailable,
      identityMode: app != null
          ? (app.sellerType == SellerType.business
              ? SellerType.business
              : SellerType.individual)
          : state.identityMode,
      businessAccountType: app?.businessType ?? state.businessAccountType,
      commercialRegisterNumber:
          app?.commercialRegisterNumber ?? state.commercialRegisterNumber,
      shortBio: cleanBio.isNotEmpty ? cleanBio : state.shortBio,
      confirmedLogoDocument: logoDoc,
      documentSlots: slots,
      submittedApplication: app,
    );
  }

  // --- Field Mutators ---

  void setOfficeName(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('officeName');
    state = state.copyWith(officeName: value, fieldErrors: errors);
  }

  void setActivity(SellerActivityOption option) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('activityCode');
    state = state.copyWith(
      activityCode: option.code,
      businessAccountType: option.businessAccountType ==
              BusinessAccountType.individual
          ? state.businessAccountType
          : option.businessAccountType,
      fieldErrors: errors,
    );
  }

  void setGovernorate(int governorateId) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('governorateId')
      ..remove('cityId');
    state = state.copyWith(
      governorateId: governorateId,
      clearCityId: true,
      fieldErrors: errors,
    );
  }

  void setCity(int cityId) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('cityId');
    state = state.copyWith(cityId: cityId, fieldErrors: errors);
  }

  void setContactPhone(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('contactPhone');
    state = state.copyWith(contactPhone: value, fieldErrors: errors);
  }

  void toggleWhatsapp(bool value) {
    state = state.copyWith(isWhatsappAvailable: value);
  }

  void setIdentityMode(SellerType mode) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('nationalIdNumber')
      ..remove('commercialRegisterNumber')
      ..remove('national_id_front')
      ..remove('national_id_back')
      ..remove('commercial_register')
      ..remove('tax_card');

    final activity =
        SellerVerificationAlgorithms.findActivityByCode(state.activityCode);
    final defaultBiz =
        activity != null &&
                activity.businessAccountType != BusinessAccountType.individual
            ? activity.businessAccountType
            : BusinessAccountType.office;

    state = state.copyWith(
      identityMode: mode,
      businessAccountType: mode == SellerType.business
          ? defaultBiz
          : BusinessAccountType.individual,
      fieldErrors: errors,
    );
  }

  void setNationalId(String value) {
    final normalized = SellerVerificationAlgorithms.normalizeDigits(value);
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('nationalIdNumber');
    state = state.copyWith(nationalIdNumber: normalized, fieldErrors: errors);
  }

  void setCommercialRegister(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('commercialRegisterNumber');
    state = state.copyWith(
      commercialRegisterNumber: value,
      fieldErrors: errors,
    );
  }

  void setTaxId(String value) {
    final errors = Map<String, String>.from(state.fieldErrors)
      ..remove('taxIdNumber');
    state = state.copyWith(taxIdNumber: value, fieldErrors: errors);
  }

  void setShortBio(String value) {
    state = state.copyWith(shortBio: value);
  }

  void startEditingFromStatus() {
    state = state.copyWith(
      currentStep: 1,
      submissionStage: WizardSubmissionStage.idle,
      clearSubmissionError: true,
    );
  }

  void goToStep(int step) {
    state = state.copyWith(
      currentStep: step.clamp(1, 3),
      clearSubmissionError: true,
    );
  }

  /// Validates Step 1 using [SellerVerificationAlgorithms] and advances to Step 2.
  bool advanceFromStep1({
    required bool hasLocationsLoaded,
    required bool isArabic,
  }) {
    final res = SellerVerificationAlgorithms.validateStep1(
      officeName: state.officeName,
      activityCode: state.activityCode,
      governorateId: state.governorateId,
      cityId: state.cityId,
      hasLocationsLoaded: hasLocationsLoaded,
      contactPhone: state.contactPhone,
      isArabic: isArabic,
    );

    if (!res.isValid) {
      state = state.copyWith(fieldErrors: res.fieldErrors);
      return false;
    }

    state = state.copyWith(
      currentStep: 2,
      fieldErrors: const {},
    );
    return true;
  }

  // --- Local Document & Avatar Picking ---

  Future<String?> pickProfileLogo(
    DocumentPickSource source, {
    required bool isArabic,
  }) async {
    try {
      final picked = await pickerService.pickDocument(source);
      if (picked == null) return null;
      if (!picked.isImage) {
        return isArabic
            ? 'يرجى اختيار صورة (JPG أو PNG أو WEBP) للشعار أو البروفايل'
            : 'Please select an image file (JPG, PNG, or WEBP)';
      }
      final err = SellerVerificationValidators.validateDocumentFile(
        picked,
        isArabic: isArabic,
      );
      if (err != null) return err;
      state = state.copyWith(profileLogoFile: picked);
      return null;
    } catch (error) {
      return ErrorMapper.map(error).userFriendlyMessage;
    }
  }

  void clearProfileLogo() {
    state = state.copyWith(clearProfileLogo: true);
  }

  Future<String?> pickDocumentForSlot({
    required String documentType,
    required DocumentPickSource source,
    required bool isArabic,
  }) async {
    try {
      final picked = await pickerService.pickDocument(source);
      if (picked == null) return null;

      final validationError = SellerVerificationValidators.validateDocumentFile(
        picked,
        isArabic: isArabic,
      );

      final nextSlots = Map<String, WizardDocumentSlot>.from(state.documentSlots);
      final nextErrors = Map<String, String>.from(state.fieldErrors)
        ..remove(documentType);

      if (validationError != null) {
        nextSlots[documentType] = state.slotFor(documentType).copyWith(
              errorMessage: validationError,
            );
        state = state.copyWith(documentSlots: nextSlots, fieldErrors: nextErrors);
        return validationError;
      }

      nextSlots[documentType] = state.slotFor(documentType).copyWith(
            localFile: picked,
            clearError: true,
          );
      state = state.copyWith(documentSlots: nextSlots, fieldErrors: nextErrors);
      return null;
    } catch (error) {
      final msg = ErrorMapper.map(error).userFriendlyMessage;
      final nextSlots = Map<String, WizardDocumentSlot>.from(state.documentSlots);
      nextSlots[documentType] = state.slotFor(documentType).copyWith(
            errorMessage: msg,
          );
      state = state.copyWith(documentSlots: nextSlots);
      return msg;
    }
  }

  void removeDocumentSlot(String documentType) {
    final nextSlots = Map<String, WizardDocumentSlot>.from(state.documentSlots);
    nextSlots[documentType] = state.slotFor(documentType).copyWith(
          clearLocalFile: true,
          clearConfirmedDocument: true,
          uploadProgress: 0.0,
          clearError: true,
        );
    state = state.copyWith(documentSlots: nextSlots);
  }

  void dismissSubmissionFailure() {
    if (state.submissionStage == WizardSubmissionStage.failed) {
      state = state.copyWith(
        submissionStage: WizardSubmissionStage.idle,
        clearSubmissionError: true,
      );
    }
  }

  /// Executes the complete 4-stage verification pipeline:
  /// 1. Algorithmic validation
  /// 2. Backend draft creation / update / reopen
  /// 3. 3-step presigned private document uploads
  /// 4. Final submission (`PENDING`) + snapshot refresh -> Step 3
  Future<bool> submitForReview({required bool isArabic}) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(
      submissionStage: WizardSubmissionStage.validating,
      overallUploadProgress: 0.08,
      clearSubmissionError: true,
    );

    final validation = SellerVerificationAlgorithms.validateStep2(
      identityMode: state.identityMode,
      nationalIdNumber: state.nationalIdNumber,
      commercialRegisterNumber: state.commercialRegisterNumber,
      hasFrontDocument: state.slotFor('national_id_front').hasFile,
      hasBackDocument: state.slotFor('national_id_back').hasFile,
      hasCommercialRegisterDocument: state.slotFor('commercial_register').hasFile,
      hasTaxCardDocument: state.slotFor('tax_card').hasFile,
      isArabic: isArabic,
    );

    if (!validation.isValid) {
      state = state.copyWith(
        fieldErrors: validation.fieldErrors,
        submissionStage: WizardSubmissionStage.idle,
        overallUploadProgress: 0.0,
      );
      return false;
    }

    try {
      // Stage 2: Persist SellerApplication draft to backend
      state = state.copyWith(
        submissionStage: WizardSubmissionStage.savingProfile,
        overallUploadProgress: 0.22,
      );

      final isBusiness = state.identityMode == SellerType.business;
      final activity =
          SellerVerificationAlgorithms.findActivityByCode(state.activityCode);
      final phoneRes = SellerVerificationAlgorithms.analyzeEgyptianPhone(
        state.contactPhone,
        isArabic: isArabic,
      );

      final descParts = <String>[];
      if (state.shortBio.trim().isNotEmpty) {
        descParts.add(state.shortBio.trim());
      }
      if (state.isWhatsappAvailable) {
        descParts.add('[WhatsApp]');
      }

      final payload = <String, dynamic>{
        'sellerType': isBusiness
            ? SellerType.business.apiValue
            : SellerType.individual.apiValue,
        'businessType': isBusiness
            ? state.businessAccountType.apiValue
            : BusinessAccountType.individual.apiValue,
        'businessName': state.officeName.trim(),
        'marketplaceSections':
            activity?.marketplaceSections ?? const ['real-estate'],
        if (activity != null)
          'serviceCategory': activity.localizedTitle(isArabic),
        if (descParts.isNotEmpty)
          'businessDescription': descParts.join('\n'),
        if (!isBusiness)
          'nationalIdNumber': SellerVerificationAlgorithms.normalizeDigits(
            state.nationalIdNumber,
          ).trim(),
        if (isBusiness)
          'commercialRegisterNumber': state.commercialRegisterNumber.trim(),
        if (isBusiness && state.taxIdNumber.trim().isNotEmpty)
          'taxIdNumber': state.taxIdNumber.trim(),
        'contactPhone': phoneRes.isValid
            ? phoneRes.normalizedE164
            : state.contactPhone.trim(),
        if (state.cityId != null) 'cityId': state.cityId,
      };

      final existingApp =
          state.submittedApplication ?? state.statusSnapshot?.application;
      final existingStatus = existingApp?.status;

      SellerApplicationEntity savedApp;
      if (existingApp == null ||
          existingStatus == null ||
          existingStatus == VerificationStatus.notSubmitted) {
        savedApp = await repository.createApplication(payload);
      } else if (existingStatus == VerificationStatus.draft) {
        savedApp = await repository.updateDraft(payload);
      } else if (existingStatus == VerificationStatus.needsChanges) {
        savedApp = await _updateCorrectionFieldsIfNeeded(existingApp, payload);
      } else if (existingStatus == VerificationStatus.rejected ||
          existingStatus == VerificationStatus.expired) {
        savedApp = await repository.resubmitApplication({
          ...payload,
          'submitImmediately': false,
        });
      } else {
        savedApp = existingApp;
      }

      state = state.copyWith(submittedApplication: savedApp);

      // Stage 3: Upload pending documents (required pair + optional logo)
      state = state.copyWith(
        submissionStage: WizardSubmissionStage.uploadingDocuments,
        overallUploadProgress: 0.35,
      );

      final pair =
          SellerVerificationAlgorithms.documentPairForMode(state.identityMode);
      final pendingUploads = <(String docType, PickedDocumentFile file, String? replaceId)>[];

      for (final docType in [pair.$1, pair.$2]) {
        final slot = state.slotFor(docType);
        if (slot.localFile != null) {
          pendingUploads.add((docType, slot.localFile!, slot.confirmedDocument?.id));
        }
      }

      if (state.profileLogoFile != null) {
        pendingUploads.add((
          'additional_document',
          state.profileLogoFile!,
          state.confirmedLogoDocument?.id,
        ));
      }

      if (pendingUploads.isNotEmpty) {
        final total = pendingUploads.length;
        for (var i = 0; i < total; i++) {
          final entry = pendingUploads[i];
          final docType = entry.$1;
          final file = entry.$2;
          final replaceId = entry.$3;

          if (docType != 'additional_document') {
            _setSlotUploading(docType, uploading: true, progress: 0.05);
          }

          final confirmed = await uploadService.uploadDocument(
            documentType: docType,
            file: file,
            replaceDocumentId: replaceId,
            onProgress: (p) {
              if (!mounted) return;
              if (docType != 'additional_document') {
                _setSlotUploading(docType, uploading: true, progress: p);
              }
              final slice = (i + p) / total;
              state = state.copyWith(
                overallUploadProgress: 0.35 + (slice * 0.48),
              );
            },
          );

          if (docType == 'additional_document') {
            state = state.copyWith(
              confirmedLogoDocument: confirmed,
              clearProfileLogo: true,
            );
          } else {
            final nextSlots =
                Map<String, WizardDocumentSlot>.from(state.documentSlots);
            nextSlots[docType] = WizardDocumentSlot(
              documentType: docType,
              confirmedDocument: confirmed,
              uploadProgress: 1.0,
              isUploading: false,
            );
            state = state.copyWith(documentSlots: nextSlots);
          }
        }
      }

      // Stage 4: Submit application to PENDING
      state = state.copyWith(
        submissionStage: WizardSubmissionStage.submittingApplication,
        overallUploadProgress: 0.90,
      );

      final isResubmitting =
          savedApp.status == VerificationStatus.needsChanges ||
          savedApp.status == VerificationStatus.rejected ||
          savedApp.status == VerificationStatus.expired;

      final finalApp = isResubmitting
          ? await repository.resubmitApplication(const {'submitImmediately': true})
          : await repository.submitApplication();

      final freshSnapshot = await repository.getMyVerificationStatus(
        forceRefresh: true,
      );

      state = state.copyWith(
        submissionStage: WizardSubmissionStage.completed,
        overallUploadProgress: 1.0,
        submittedApplication: finalApp,
        statusSnapshot: freshSnapshot,
        currentStep: 3,
      );
      return true;
    } catch (error) {
      final failure = ErrorMapper.map(error);
      state = state.copyWith(
        submissionStage: WizardSubmissionStage.failed,
        submissionErrorMessage: failure.userFriendlyMessage,
        fieldErrors: failure is ValidationFailure ? failure.fieldErrors : state.fieldErrors,
      );
      return false;
    }
  }

  Future<SellerApplicationEntity> _updateCorrectionFieldsIfNeeded(
    SellerApplicationEntity existingApp,
    Map<String, dynamic> fullPayload,
  ) async {
    final allowed = existingApp.correctionFields;
    if (allowed.isEmpty) {
      return repository.updateDraft(fullPayload);
    }
    final filtered = <String, dynamic>{};
    for (final key in allowed) {
      if (fullPayload.containsKey(key)) {
        filtered[key] = fullPayload[key];
      }
    }
    if (filtered.isEmpty) {
      return existingApp;
    }
    return repository.updateDraft(filtered);
  }

  void _setSlotUploading(
    String documentType, {
    required bool uploading,
    required double progress,
  }) {
    final nextSlots = Map<String, WizardDocumentSlot>.from(state.documentSlots);
    nextSlots[documentType] = state.slotFor(documentType).copyWith(
          isUploading: uploading,
          uploadProgress: progress,
          clearError: true,
        );
    state = state.copyWith(documentSlots: nextSlots);
  }
}
