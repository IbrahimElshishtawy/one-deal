import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/core/errors/error_mapper.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';
import 'package:market_space/features/seller_verification/services/document_upload/document_upload_service.dart';

// ============================================================================
// 1. SELLER ONBOARDING STATE & NOTIFIER
// ============================================================================

class SellerOnboardingState {
  final bool isLoading;
  final VerificationStatusSnapshot? snapshot;
  final AppFailure? failure;

  const SellerOnboardingState({
    this.isLoading = false,
    this.snapshot,
    this.failure,
  });

  SellerOnboardingState copyWith({
    bool? isLoading,
    VerificationStatusSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SellerOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class SellerOnboardingNotifier extends StateNotifier<SellerOnboardingState> {
  final SellerVerificationRepository repository;

  SellerOnboardingNotifier({required this.repository})
      : super(const SellerOnboardingState());

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final snapshot = await repository.getMyVerificationStatus(
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(isLoading: false, snapshot: snapshot);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        failure: ErrorMapper.map(error),
      );
    }
  }
}

// ============================================================================
// 2. SELLER TYPE SELECTION STATE & NOTIFIER
// ============================================================================

class SellerTypeSelectionState {
  final SellerType selectedType;
  final BusinessAccountType selectedBusinessType;

  const SellerTypeSelectionState({
    this.selectedType = SellerType.individual,
    this.selectedBusinessType = BusinessAccountType.individual,
  });

  SellerTypeSelectionState copyWith({
    SellerType? selectedType,
    BusinessAccountType? selectedBusinessType,
  }) {
    return SellerTypeSelectionState(
      selectedType: selectedType ?? this.selectedType,
      selectedBusinessType: selectedBusinessType ?? this.selectedBusinessType,
    );
  }
}

class SellerTypeSelectionNotifier
    extends StateNotifier<SellerTypeSelectionState> {
  SellerTypeSelectionNotifier() : super(const SellerTypeSelectionState());

  void selectSellerType(SellerType type) {
    final defaultBizType = type == SellerType.business
        ? BusinessAccountType.company
        : BusinessAccountType.individual;
    state = state.copyWith(
      selectedType: type,
      selectedBusinessType: defaultBizType,
    );
  }

  void selectBusinessType(BusinessAccountType type) {
    state = state.copyWith(selectedBusinessType: type);
  }

  void hydrateFromApplication(SellerApplicationEntity? app) {
    if (app == null) return;
    state = SellerTypeSelectionState(
      selectedType: app.sellerType,
      selectedBusinessType: app.businessType,
    );
  }
}

// ============================================================================
// 3. SELLER INFORMATION FORM STATE & NOTIFIER
// ============================================================================

class SellerInformationState {
  final String fullName;
  final String businessName;
  final String nationalIdNumber;
  final String commercialRegisterNumber;
  final String taxIdNumber;
  final String contactPersonName;
  final String contactPhone;
  final String contactEmail;
  final String address;
  final int? governorateId;
  final int? cityId;
  final List<String> marketplaceSections;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final AppFailure? failure;
  final SellerApplicationEntity? savedApplication;

  const SellerInformationState({
    this.fullName = '',
    this.businessName = '',
    this.nationalIdNumber = '',
    this.commercialRegisterNumber = '',
    this.taxIdNumber = '',
    this.contactPersonName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.address = '',
    this.governorateId,
    this.cityId,
    this.marketplaceSections = const [],
    this.isSaving = false,
    this.fieldErrors = const {},
    this.failure,
    this.savedApplication,
  });

  SellerInformationState copyWith({
    String? fullName,
    String? businessName,
    String? nationalIdNumber,
    String? commercialRegisterNumber,
    String? taxIdNumber,
    String? contactPersonName,
    String? contactPhone,
    String? contactEmail,
    String? address,
    int? governorateId,
    int? cityId,
    bool clearCityId = false,
    List<String>? marketplaceSections,
    bool? isSaving,
    Map<String, String>? fieldErrors,
    AppFailure? failure,
    bool clearFailure = false,
    SellerApplicationEntity? savedApplication,
  }) {
    return SellerInformationState(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      commercialRegisterNumber:
          commercialRegisterNumber ?? this.commercialRegisterNumber,
      taxIdNumber: taxIdNumber ?? this.taxIdNumber,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      governorateId: governorateId ?? this.governorateId,
      cityId: clearCityId ? null : (cityId ?? this.cityId),
      marketplaceSections: marketplaceSections ?? this.marketplaceSections,
      isSaving: isSaving ?? this.isSaving,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : (failure ?? this.failure),
      savedApplication: savedApplication ?? this.savedApplication,
    );
  }
}

class SellerInformationNotifier extends StateNotifier<SellerInformationState> {
  final SellerVerificationRepository repository;

  SellerInformationNotifier({required this.repository})
      : super(const SellerInformationState());

  void updateField({
    String? fullName,
    String? businessName,
    String? nationalIdNumber,
    String? commercialRegisterNumber,
    String? taxIdNumber,
    String? contactPersonName,
    String? contactPhone,
    String? contactEmail,
    String? address,
    int? governorateId,
    int? cityId,
    bool clearCityId = false,
    List<String>? marketplaceSections,
  }) {
    state = state.copyWith(
      fullName: fullName,
      businessName: businessName,
      nationalIdNumber: nationalIdNumber,
      commercialRegisterNumber: commercialRegisterNumber,
      taxIdNumber: taxIdNumber,
      contactPersonName: contactPersonName,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      address: address,
      governorateId: governorateId,
      cityId: cityId,
      clearCityId: clearCityId,
      marketplaceSections: marketplaceSections,
      fieldErrors: const {},
      clearFailure: true,
    );
  }

  void toggleSection(String slug) {
    final current = List<String>.from(state.marketplaceSections);
    if (current.contains(slug)) {
      current.remove(slug);
    } else {
      current.add(slug);
    }
    state = state.copyWith(marketplaceSections: current);
  }

  void hydrateFromApplication(SellerApplicationEntity? app) {
    if (app == null) return;
    state = state.copyWith(
      fullName: app.sellerType == SellerType.business
          ? state.fullName
          : (app.businessName ?? state.fullName),
      businessName: app.businessName ?? state.businessName,
      commercialRegisterNumber:
          app.commercialRegisterNumber ?? state.commercialRegisterNumber,
      contactPersonName:
          app.authorizedRepresentativeName ?? state.contactPersonName,
      contactPhone: app.contactPhone ?? state.contactPhone,
      contactEmail: app.contactEmail ?? state.contactEmail,
      address: app.address ?? state.address,
      cityId: app.cityId ?? state.cityId,
      marketplaceSections: app.marketplaceSections.isNotEmpty
          ? app.marketplaceSections
          : state.marketplaceSections,
      savedApplication: app,
    );
  }

  /// Creates or updates the backend DRAFT SellerApplication before document uploads.
  Future<SellerApplicationEntity?> saveToBackend({
    required SellerType sellerType,
    required BusinessAccountType businessType,
    required bool hasExistingDraft,
    required bool isArabic,
  }) async {
    final errors = <String, String>{};
    final isBusiness = sellerType == SellerType.business;

    final effectiveName = isBusiness ? state.businessName : state.fullName;
    final nameErr =
        SellerVerificationValidators.validateName(effectiveName, isArabic: isArabic);
    if (nameErr != null) {
      errors[isBusiness ? 'businessName' : 'fullName'] = nameErr;
    }

    if (isBusiness) {
      final crErr = SellerVerificationValidators.validateCommercialRegister(
        state.commercialRegisterNumber,
        isArabic: isArabic,
      );
      if (crErr != null) errors['commercialRegisterNumber'] = crErr;
    } else {
      final nidErr = SellerVerificationValidators.validateNationalId(
        state.nationalIdNumber,
        isArabic: isArabic,
      );
      if (nidErr != null) errors['nationalIdNumber'] = nidErr;
    }

    final phoneErr = SellerVerificationValidators.validatePhone(
      state.contactPhone,
      isArabic: isArabic,
    );
    if (phoneErr != null) errors['contactPhone'] = phoneErr;

    final emailErr = SellerVerificationValidators.validateEmail(
      state.contactEmail,
      isArabic: isArabic,
    );
    if (emailErr != null) errors['contactEmail'] = emailErr;

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return null;
    }

    state = state.copyWith(
      isSaving: true,
      fieldErrors: const {},
      clearFailure: true,
    );

    final payload = <String, dynamic>{
      'sellerType': sellerType.apiValue,
      'businessType': businessType.apiValue,
      'businessName': effectiveName.trim(),
      if (state.marketplaceSections.isNotEmpty)
        'marketplaceSections': state.marketplaceSections,
      if (!isBusiness && state.nationalIdNumber.trim().isNotEmpty)
        'nationalIdNumber': state.nationalIdNumber.trim(),
      if (isBusiness && state.commercialRegisterNumber.trim().isNotEmpty)
        'commercialRegisterNumber': state.commercialRegisterNumber.trim(),
      if (isBusiness && state.taxIdNumber.trim().isNotEmpty)
        'taxIdNumber': state.taxIdNumber.trim(),
      if (isBusiness && state.contactPersonName.trim().isNotEmpty)
        'authorizedRepresentativeName': state.contactPersonName.trim(),
      if (state.contactPhone.trim().isNotEmpty)
        'contactPhone': state.contactPhone.trim(),
      if (state.contactEmail.trim().isNotEmpty)
        'contactEmail': state.contactEmail.trim(),
      if (state.cityId != null) 'cityId': state.cityId,
      if (state.address.trim().isNotEmpty) 'address': state.address.trim(),
    };

    try {
      final saved = hasExistingDraft
          ? await repository.updateDraft(payload)
          : await repository.createApplication(payload);
      state = state.copyWith(isSaving: false, savedApplication: saved);
      return saved;
    } catch (error) {
      final failure = ErrorMapper.map(error);
      state = state.copyWith(
        isSaving: false,
        failure: failure,
        fieldErrors: failure is ValidationFailure ? failure.fieldErrors : const {},
      );
      return null;
    }
  }
}

// ============================================================================
// 4. VERIFICATION REQUIREMENTS STATE & NOTIFIER
// ============================================================================

class VerificationRequirementsState {
  final bool isLoading;
  final List<SellerVerificationRequirementEntity> requirements;
  final AppFailure? failure;

  const VerificationRequirementsState({
    this.isLoading = false,
    this.requirements = const [],
    this.failure,
  });

  List<SellerVerificationRequirementEntity> get requiredDocs =>
      requirements.where((r) => r.isRequired).toList(growable: false);

  List<SellerVerificationRequirementEntity> get optionalDocs =>
      requirements.where((r) => !r.isRequired).toList(growable: false);

  VerificationRequirementsState copyWith({
    bool? isLoading,
    List<SellerVerificationRequirementEntity>? requirements,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return VerificationRequirementsState(
      isLoading: isLoading ?? this.isLoading,
      requirements: requirements ?? this.requirements,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class VerificationRequirementsNotifier
    extends StateNotifier<VerificationRequirementsState> {
  final SellerVerificationRepository repository;

  VerificationRequirementsNotifier({required this.repository})
      : super(const VerificationRequirementsState());

  Future<void> load({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final reqs = await repository.getRequirements(
        sellerType: sellerType,
        marketplaceSections: marketplaceSections,
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(isLoading: false, requirements: reqs);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        failure: ErrorMapper.map(error),
      );
    }
  }
}

// ============================================================================
// 5. DOCUMENT UPLOAD STATE & NOTIFIER
// ============================================================================

enum DocumentUploadSlotStatus {
  idle,
  uploading,
  uploaded,
  error,
}

class DocumentUploadItemState {
  final String documentType;
  final DocumentUploadSlotStatus status;
  final double progress;
  final PickedDocumentFile? localPreviewFile;
  final SellerDocumentEntity? confirmedDocument;
  final String? errorMessage;

  const DocumentUploadItemState({
    required this.documentType,
    this.status = DocumentUploadSlotStatus.idle,
    this.progress = 0.0,
    this.localPreviewFile,
    this.confirmedDocument,
    this.errorMessage,
  });

  DocumentUploadItemState copyWith({
    DocumentUploadSlotStatus? status,
    double? progress,
    PickedDocumentFile? localPreviewFile,
    bool clearLocalPreview = false,
    SellerDocumentEntity? confirmedDocument,
    bool clearConfirmedDocument = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentUploadItemState(
      documentType: documentType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPreviewFile: clearLocalPreview
          ? null
          : (localPreviewFile ?? this.localPreviewFile),
      confirmedDocument: clearConfirmedDocument
          ? null
          : (confirmedDocument ?? this.confirmedDocument),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DocumentUploadState {
  final Map<String, DocumentUploadItemState> items;

  const DocumentUploadState({this.items = const {}});

  DocumentUploadItemState slotFor(String documentType) {
    return items[documentType] ??
        DocumentUploadItemState(documentType: documentType);
  }

  List<SellerDocumentEntity> get confirmedDocuments => items.values
      .map((e) => e.confirmedDocument)
      .whereType<SellerDocumentEntity>()
      .toList(growable: false);

  bool get hasAnyUploading =>
      items.values.any((e) => e.status == DocumentUploadSlotStatus.uploading);

  DocumentUploadState copyWith({Map<String, DocumentUploadItemState>? items}) {
    return DocumentUploadState(items: items ?? this.items);
  }
}

class DocumentUploadNotifier extends StateNotifier<DocumentUploadState> {
  final DocumentPickerService pickerService;
  final DocumentUploadService uploadService;
  final SellerVerificationRepository repository;
  final Map<String, CancelToken> _cancelTokens = {};

  DocumentUploadNotifier({
    required this.pickerService,
    required this.uploadService,
    required this.repository,
  }) : super(const DocumentUploadState());

  void hydrateExistingDocuments(List<SellerDocumentEntity> docs) {
    final next = Map<String, DocumentUploadItemState>.from(state.items);
    for (final doc in docs) {
      if (!doc.isCurrent) continue;
      final existing = next[doc.documentType];
      next[doc.documentType] = DocumentUploadItemState(
        documentType: doc.documentType,
        status: doc.status == SellerDocumentStatus.rejected
            ? DocumentUploadSlotStatus.error
            : DocumentUploadSlotStatus.uploaded,
        progress: 1.0,
        localPreviewFile: existing?.localPreviewFile,
        confirmedDocument: doc,
        errorMessage: doc.status == SellerDocumentStatus.rejected
            ? doc.rejectionReason
            : null,
      );
    }
    state = state.copyWith(items: next);
  }

  void _updateSlot(String documentType, DocumentUploadItemState slot) {
    final next = Map<String, DocumentUploadItemState>.from(state.items);
    next[documentType] = slot;
    state = state.copyWith(items: next);
  }

  Future<void> pickAndUpload({
    required SellerVerificationRequirementEntity requirement,
    required DocumentPickSource source,
    required bool isArabic,
    String? replaceDocumentId,
  }) async {
    try {
      final picked = await pickerService.pickDocument(source);
      if (picked == null) return;
      await uploadPickedFile(
        requirement: requirement,
        file: picked,
        isArabic: isArabic,
        replaceDocumentId: replaceDocumentId,
      );
    } catch (error) {
      final failure = ErrorMapper.map(error);
      _updateSlot(
        requirement.documentType,
        state.slotFor(requirement.documentType).copyWith(
              status: DocumentUploadSlotStatus.error,
              errorMessage: failure.userFriendlyMessage,
            ),
      );
    }
  }

  Future<void> uploadPickedFile({
    required SellerVerificationRequirementEntity requirement,
    required PickedDocumentFile file,
    required bool isArabic,
    String? replaceDocumentId,
  }) async {
    final docType = requirement.documentType;
    final validationError = SellerVerificationValidators.validateDocumentFile(
      file,
      requirement: requirement,
      isArabic: isArabic,
    );
    if (validationError != null) {
      _updateSlot(
        docType,
        state.slotFor(docType).copyWith(
              status: DocumentUploadSlotStatus.error,
              localPreviewFile: file,
              errorMessage: validationError,
            ),
      );
      return;
    }

    _cancelTokens[docType]?.cancel('Replaced by new upload');
    final cancelToken = CancelToken();
    _cancelTokens[docType] = cancelToken;

    _updateSlot(
      docType,
      state.slotFor(docType).copyWith(
            status: DocumentUploadSlotStatus.uploading,
            progress: 0.05,
            localPreviewFile: file,
            clearError: true,
          ),
    );

    try {
      final confirmed = await uploadService.uploadDocument(
        documentType: docType,
        file: file,
        requirementId: requirement.id.isNotEmpty ? requirement.id : null,
        replaceDocumentId: replaceDocumentId,
        cancelToken: cancelToken,
        onProgress: (p) {
          if (!mounted) return;
          _updateSlot(
            docType,
            state.slotFor(docType).copyWith(
                  status: DocumentUploadSlotStatus.uploading,
                  progress: p,
                ),
          );
        },
      );

      _updateSlot(
        docType,
        state.slotFor(docType).copyWith(
              status: DocumentUploadSlotStatus.uploaded,
              progress: 1.0,
              localPreviewFile: file,
              confirmedDocument: confirmed,
              clearError: true,
            ),
      );
    } catch (error) {
      final failure = ErrorMapper.map(error);
      _updateSlot(
        docType,
        state.slotFor(docType).copyWith(
              status: DocumentUploadSlotStatus.error,
              progress: 0.0,
              errorMessage: failure.userFriendlyMessage,
            ),
      );
    } finally {
      _cancelTokens.remove(docType);
    }
  }

  Future<void> retryUpload({
    required SellerVerificationRequirementEntity requirement,
    required bool isArabic,
  }) async {
    final slot = state.slotFor(requirement.documentType);
    if (slot.localPreviewFile == null) return;
    await uploadPickedFile(
      requirement: requirement,
      file: slot.localPreviewFile!,
      isArabic: isArabic,
      replaceDocumentId: slot.confirmedDocument?.id,
    );
  }

  Future<void> removeDocument(String documentType) async {
    final slot = state.slotFor(documentType);
    _cancelTokens[documentType]?.cancel('Cancelled by user');
    _cancelTokens.remove(documentType);

    if (slot.confirmedDocument != null) {
      try {
        await repository.deleteDocument(slot.confirmedDocument!.id);
      } catch (error) {
        final failure = ErrorMapper.map(error);
        _updateSlot(
          documentType,
          slot.copyWith(
            status: DocumentUploadSlotStatus.error,
            errorMessage: failure.userFriendlyMessage,
          ),
        );
        return;
      }
    }

    _updateSlot(
      documentType,
      DocumentUploadItemState(documentType: documentType),
    );
  }

  @override
  void dispose() {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) token.cancel('Notifier disposed');
    }
    _cancelTokens.clear();
    super.dispose();
  }
}

// ============================================================================
// 6. VERIFICATION SUBMISSION STATE & NOTIFIER
// ============================================================================

class VerificationSubmissionState {
  final bool isSubmitting;
  final bool isConfirmed;
  final SellerApplicationEntity? submittedApplication;
  final AppFailure? failure;

  const VerificationSubmissionState({
    this.isSubmitting = false,
    this.isConfirmed = false,
    this.submittedApplication,
    this.failure,
  });

  VerificationSubmissionState copyWith({
    bool? isSubmitting,
    bool? isConfirmed,
    SellerApplicationEntity? submittedApplication,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return VerificationSubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      submittedApplication: submittedApplication ?? this.submittedApplication,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class VerificationSubmissionNotifier
    extends StateNotifier<VerificationSubmissionState> {
  final SellerVerificationRepository repository;

  VerificationSubmissionNotifier({required this.repository})
      : super(const VerificationSubmissionState());

  void toggleConfirmation(bool value) {
    state = state.copyWith(isConfirmed: value, clearFailure: true);
  }

  Future<SellerApplicationEntity?> submit({
    bool isResubmission = false,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      final result = isResubmission
          ? await repository.resubmitApplication(const {'submitImmediately': true})
          : await repository.submitApplication();
      state = state.copyWith(
        isSubmitting: false,
        submittedApplication: result,
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        failure: ErrorMapper.map(error),
      );
      return null;
    }
  }
}

// ============================================================================
// 7. VERIFICATION TRACKING STATE & NOTIFIER
// ============================================================================

class VerificationTrackingState {
  final bool isLoading;
  final VerificationStatusSnapshot? snapshot;
  final List<VerificationHistoryItemEntity> history;
  final AppFailure? failure;

  const VerificationTrackingState({
    this.isLoading = false,
    this.snapshot,
    this.history = const [],
    this.failure,
  });

  VerificationTrackingState copyWith({
    bool? isLoading,
    VerificationStatusSnapshot? snapshot,
    List<VerificationHistoryItemEntity>? history,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return VerificationTrackingState(
      isLoading: isLoading ?? this.isLoading,
      snapshot: snapshot ?? this.snapshot,
      history: history ?? this.history,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class VerificationTrackingNotifier
    extends StateNotifier<VerificationTrackingState> {
  final SellerVerificationRepository repository;

  VerificationTrackingNotifier({required this.repository})
      : super(const VerificationTrackingState());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final snapshot = await repository.getMyVerificationStatus(
        forceRefresh: true,
      );
      List<VerificationHistoryItemEntity> history = const [];
      try {
        history = await repository.getMyHistory();
      } catch (_) {
        // Non-fatal: history may be empty for users with no application yet.
      }
      state = state.copyWith(
        isLoading: false,
        snapshot: snapshot,
        history: history,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        failure: ErrorMapper.map(error),
      );
    }
  }
}

// ============================================================================
// 8. BUSINESS UPGRADE STATE & NOTIFIER
// ============================================================================

class BusinessUpgradeState {
  final bool isLoading;
  final bool isSubmitting;
  final BusinessUpgradeSnapshot? snapshot;
  final AppFailure? failure;
  final Map<String, String> fieldErrors;

  const BusinessUpgradeState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.snapshot,
    this.failure,
    this.fieldErrors = const {},
  });

  BusinessUpgradeState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    BusinessUpgradeSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
    Map<String, String>? fieldErrors,
  }) {
    return BusinessUpgradeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : (failure ?? this.failure),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class BusinessUpgradeNotifier extends StateNotifier<BusinessUpgradeState> {
  final SellerVerificationRepository repository;

  BusinessUpgradeNotifier({required this.repository})
      : super(const BusinessUpgradeState());

  Future<void> load({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final snapshot = await repository.getBusinessUpgradeStatus(
        forceRefresh: forceRefresh,
      );
      state = state.copyWith(isLoading: false, snapshot: snapshot);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        failure: ErrorMapper.map(error),
      );
    }
  }

  Future<SellerApplicationEntity?> startUpgrade({
    required String businessName,
    required String commercialRegisterNumber,
    required BusinessAccountType businessType,
    String? taxIdNumber,
    String? authorizedRepresentativeName,
    String? address,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      fieldErrors: const {},
    );
    try {
      final app = await repository.createBusinessUpgrade({
        'businessType': businessType.apiValue,
        'businessName': businessName.trim(),
        'commercialRegisterNumber': commercialRegisterNumber.trim(),
        if (taxIdNumber != null && taxIdNumber.trim().isNotEmpty)
          'taxIdNumber': taxIdNumber.trim(),
        if (authorizedRepresentativeName != null &&
            authorizedRepresentativeName.trim().isNotEmpty)
          'authorizedRepresentativeName': authorizedRepresentativeName.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
      });
      await load(forceRefresh: true);
      state = state.copyWith(isSubmitting: false);
      return app;
    } catch (error) {
      final failure = ErrorMapper.map(error);
      state = state.copyWith(
        isSubmitting: false,
        failure: failure,
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
      );
      return null;
    }
  }

  Future<SellerApplicationEntity?> submitUpgrade({
    bool isResubmission = false,
  }) async {
    if (state.isSubmitting) return null;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    try {
      final app = isResubmission
          ? await repository
              .resubmitBusinessUpgrade(const {'submitImmediately': true})
          : await repository.submitBusinessUpgrade();
      await load(forceRefresh: true);
      state = state.copyWith(isSubmitting: false);
      return app;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        failure: ErrorMapper.map(error),
      );
      return null;
    }
  }
}
