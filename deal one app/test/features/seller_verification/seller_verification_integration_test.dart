import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_notifiers.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';
import 'package:market_space/features/seller_verification/services/document_upload/document_upload_service.dart';

class _InMemorySellerVerificationRepository
    implements SellerVerificationRepository {
  VerificationStatus status = VerificationStatus.notSubmitted;
  SellerType sellerType = SellerType.individual;
  VerificationTier tier = VerificationTier.none;
  String? rejectionReason;
  String? suspensionReason;
  String accountId = 'acc-preserved-001';
  final List<SellerDocumentEntity> docs = [];
  SellerApplicationEntity? activeApp;
  SellerApplicationEntity? upgradeApp;
  int createdAccountsCount = 0;

  @override
  Future<List<SellerVerificationRequirementEntity>> getRequirements({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
    bool forceRefresh = false,
  }) async {
    if (sellerType == SellerType.business) {
      return const [
        SellerVerificationRequirementEntity(
          id: 'req-cr',
          sellerType: 'BUSINESS',
          documentType: 'commercial_register',
          displayName: 'Commercial Register',
          isRequired: true,
        ),
        SellerVerificationRequirementEntity(
          id: 'req-tax',
          sellerType: 'BUSINESS',
          documentType: 'tax_card',
          displayName: 'Tax Card',
          isRequired: true,
        ),
      ];
    }
    return const [
      SellerVerificationRequirementEntity(
        id: 'req-nid-f',
        sellerType: 'INDIVIDUAL',
        documentType: 'national_id_front',
        displayName: 'National ID Front',
        isRequired: true,
      ),
      SellerVerificationRequirementEntity(
        id: 'req-nid-b',
        sellerType: 'INDIVIDUAL',
        documentType: 'national_id_back',
        displayName: 'National ID Back',
        isRequired: true,
      ),
    ];
  }

  @override
  Future<SellerApplicationEntity> createApplication(
    Map<String, dynamic> payload,
  ) async {
    sellerType = SellerType.fromApi(payload['sellerType']?.toString());
    status = VerificationStatus.draft;
    activeApp = SellerApplicationEntity(
      id: 'app-1',
      userId: 'user-1',
      status: status,
      sellerType: sellerType,
      businessName: payload['businessName']?.toString(),
    );
    return activeApp!;
  }

  @override
  Future<SellerApplicationEntity> updateDraft(Map<String, dynamic> payload) async {
    return createApplication(payload);
  }

  @override
  Future<PrivateUploadTargetEntity> requestDocumentUploadUrl({
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    return PrivateUploadTargetEntity(
      applicationId: upgradeApp?.id ?? activeApp?.id ?? 'app-1',
      documentType: documentType,
      storageKey: 'private/seller-verification/user-1/app-1/$documentType.jpg',
      uploadUrl: 'https://private-storage.deal-one.local/v1/docs/test',
      expiresInSeconds: 900,
      contentType: mimeType,
      maxSizeBytes: 10 * 1024 * 1024,
    );
  }

  @override
  Future<void> uploadDocumentBinary({
    required String uploadUrl,
    required PickedDocumentFile file,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    onSendProgress?.call(file.sizeBytes, file.sizeBytes);
  }

  @override
  Future<SellerDocumentEntity> confirmDocument({
    required String documentType,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
    String? requirementId,
  }) async {
    final doc = SellerDocumentEntity(
      id: 'doc-${docs.length + 1}',
      applicationId: upgradeApp?.id ?? activeApp?.id ?? 'app-1',
      documentType: documentType,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      status: SellerDocumentStatus.uploaded,
    );
    docs.removeWhere((d) => d.documentType == documentType);
    docs.add(doc);
    return doc;
  }

  @override
  Future<SellerDocumentEntity> replaceDocument({
    required String documentId,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
  }) async {
    final existing = docs.firstWhere((d) => d.id == documentId);
    return confirmDocument(
      documentType: existing.documentType,
      storageKey: storageKey,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    docs.removeWhere((d) => d.id == documentId);
  }

  @override
  Future<SellerApplicationEntity> submitApplication() async {
    status = VerificationStatus.pending;
    activeApp = SellerApplicationEntity(
      id: activeApp!.id,
      userId: activeApp!.userId,
      status: status,
      sellerType: sellerType,
      businessName: activeApp!.businessName,
      submittedAt: DateTime.now(),
      documents: List.unmodifiable(docs),
    );
    return activeApp!;
  }

  @override
  Future<VerificationStatusSnapshot> devApproveMyApplication() async {
    simulateAdminApproveInitial();
    return getMyVerificationStatus(forceRefresh: true);
  }

  @override
  Future<SellerApplicationEntity> resubmitApplication(
    Map<String, dynamic> payload,
  ) =>
      submitApplication();

  void simulateAdminApproveInitial() {
    status = VerificationStatus.approved;
    tier = sellerType == SellerType.business
        ? VerificationTier.businessVerified
        : VerificationTier.identityVerified;
    createdAccountsCount = 1;
  }

  void simulateAdminReject(String reason) {
    status = VerificationStatus.rejected;
    rejectionReason = reason;
    tier = VerificationTier.none;
  }

  void simulateAdminSuspend(String reason) {
    status = VerificationStatus.suspended;
    suspensionReason = reason;
    tier = VerificationTier.none;
  }

  void simulateAdminApproveUpgrade() {
    sellerType = SellerType.business;
    tier = VerificationTier.businessVerified;
    // Account ID is preserved, NO second account created
    upgradeApp = SellerApplicationEntity(
      id: upgradeApp!.id,
      userId: upgradeApp!.userId,
      accountId: accountId,
      applicationType: SellerApplicationType.businessUpgrade,
      status: VerificationStatus.approved,
      sellerType: SellerType.business,
      derivedVerificationTier: VerificationTier.businessVerified,
    );
  }

  @override
  Future<VerificationStatusSnapshot> getMyVerificationStatus({
    bool forceRefresh = false,
  }) async {
    VerificationBadgeEntity? badge;
    if (status == VerificationStatus.approved) {
      if (tier == VerificationTier.businessVerified) {
        badge = const VerificationBadgeEntity(
          code: VerificationTier.businessVerified,
          label: 'شركة / مكتب موثق',
        );
      } else if (tier == VerificationTier.identityVerified) {
        badge = const VerificationBadgeEntity(
          code: VerificationTier.identityVerified,
          label: 'هوية موثقة',
        );
      }
    }
    return VerificationStatusSnapshot(
      userId: 'user-1',
      sellerStatus: status,
      sellerType: sellerType,
      verificationTier: tier,
      verificationBadge: badge,
      capabilities: SellerCapabilitiesEntity(
        canCreateListing: status.isApproved,
        canUpgradeToBusiness:
            status.isApproved && tier == VerificationTier.identityVerified,
      ),
      sellerSuspensionReason: suspensionReason,
      application: activeApp != null
          ? SellerApplicationEntity(
              id: activeApp!.id,
              userId: activeApp!.userId,
              accountId: createdAccountsCount > 0 ? accountId : null,
              status: status,
              sellerType: sellerType,
              businessName: activeApp!.businessName,
              rejectionReason: rejectionReason,
              suspensionReason: suspensionReason,
              documents: List.unmodifiable(docs),
            )
          : null,
      businessUpgradeApplication: upgradeApp,
    );
  }

  @override
  Future<List<VerificationHistoryItemEntity>> getMyHistory() async => [
        VerificationHistoryItemEntity(
          id: 'h-1',
          applicationId: 'app-1',
          actorType: 'system',
          previousStatus: VerificationStatus.draft,
          newStatus: status,
          createdAt: DateTime.now(),
        ),
      ];

  @override
  Future<BusinessUpgradeSnapshot> getBusinessUpgradeStatus({
    bool forceRefresh = false,
  }) async {
    return BusinessUpgradeSnapshot(
      accountId: accountId,
      currentSellerType: sellerType,
      currentVerificationTier: tier,
      currentVerificationBadge: tier == VerificationTier.identityVerified
          ? const VerificationBadgeEntity(
              code: VerificationTier.identityVerified,
              label: 'هوية موثقة',
            )
          : tier == VerificationTier.businessVerified
              ? const VerificationBadgeEntity(
                  code: VerificationTier.businessVerified,
                  label: 'شركة / مكتب موثق',
                )
              : null,
      eligibleForUpgrade: tier == VerificationTier.identityVerified,
      businessRequirements: await getRequirements(sellerType: SellerType.business),
      application: upgradeApp,
    );
  }

  @override
  Future<SellerApplicationEntity> createBusinessUpgrade(
    Map<String, dynamic> payload,
  ) async {
    upgradeApp = SellerApplicationEntity(
      id: 'upgrade-1',
      userId: 'user-1',
      accountId: accountId,
      applicationType: SellerApplicationType.businessUpgrade,
      status: VerificationStatus.draft,
      sellerType: SellerType.business,
      businessName: payload['businessName']?.toString(),
    );
    return upgradeApp!;
  }

  @override
  Future<SellerApplicationEntity> submitBusinessUpgrade() async {
    upgradeApp = SellerApplicationEntity(
      id: upgradeApp!.id,
      userId: upgradeApp!.userId,
      accountId: accountId,
      applicationType: SellerApplicationType.businessUpgrade,
      status: VerificationStatus.pending,
      sellerType: SellerType.business,
    );
    return upgradeApp!;
  }

  @override
  Future<SellerApplicationEntity> resubmitBusinessUpgrade(
    Map<String, dynamic> payload,
  ) =>
      submitBusinessUpgrade();
}

class _FakePicker implements DocumentPickerService {
  @override
  Future<PickedDocumentFile?> pickDocument(DocumentPickSource source) async {
    return PickedDocumentFile(
      fileName: 'doc.jpg',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
    );
  }

  @override
  Future<PickedDocumentFile> readFromFilePath(String path) async {
    return (await pickDocument(DocumentPickSource.file))!;
  }
}

void main() {
  test('Full lifecycle: Individual -> Pending -> Approved (هوية موثقة) -> Business Upgrade (شركة / مكتب موثق) -> Suspended (badge removed)', () async {
    final repo = _InMemorySellerVerificationRepository();
    final uploadService = DocumentUploadService(repository: repo);
    final infoNotifier = SellerInformationNotifier(repository: repo);
    final reqNotifier = VerificationRequirementsNotifier(repository: repo);
    final docNotifier = DocumentUploadNotifier(
      pickerService: _FakePicker(),
      uploadService: uploadService,
      repository: repo,
    );
    final subNotifier = VerificationSubmissionNotifier(repository: repo);
    final trackNotifier = VerificationTrackingNotifier(repository: repo);
    final upgradeNotifier = BusinessUpgradeNotifier(repository: repo);

    // 1. Individual seller saves draft info
    infoNotifier.updateField(
      fullName: 'Karim Broker',
      nationalIdNumber: '29501011234567',
      address: 'Maadi, Cairo',
    );
    final draft = await infoNotifier.saveToBackend(
      sellerType: SellerType.individual,
      businessType: BusinessAccountType.individual,
      hasExistingDraft: false,
      isArabic: false,
    );
    expect(draft, isNotNull);

    // 2. Load dynamic individual requirements & upload National ID front + back
    await reqNotifier.load(sellerType: SellerType.individual);
    expect(reqNotifier.state.requiredDocs.length, 2);
    for (final req in reqNotifier.state.requiredDocs) {
      await docNotifier.pickAndUpload(
        requirement: req,
        source: DocumentPickSource.gallery,
        isArabic: false,
      );
    }
    expect(docNotifier.state.confirmedDocuments.length, 2);

    // 3. Submit -> Pending (no badge yet)
    final submitted = await subNotifier.submit();
    expect(submitted?.status, VerificationStatus.pending);
    await trackNotifier.refresh();
    expect(trackNotifier.state.snapshot?.activeBadge, isNull);

    // 4. Admin rejects -> reason displayed -> resubmit -> Admin approves
    repo.simulateAdminReject('Back side of ID is slightly blurry');
    await trackNotifier.refresh();
    expect(trackNotifier.state.snapshot?.sellerStatus, VerificationStatus.rejected);
    expect(
      trackNotifier.state.snapshot?.application?.rejectionReason,
      'Back side of ID is slightly blurry',
    );
    expect(trackNotifier.state.snapshot?.activeBadge, isNull);

    await subNotifier.submit(isResubmission: true);
    repo.simulateAdminApproveInitial();
    await trackNotifier.refresh();
    expect(trackNotifier.state.snapshot?.verificationTier, VerificationTier.identityVerified);
    expect(trackNotifier.state.snapshot?.activeBadge?.label, 'هوية موثقة');
    expect(trackNotifier.state.snapshot?.capabilities.canUpgradeToBusiness, isTrue);

    // 5. Business upgrade preserves existing account & IDENTITY_VERIFIED while pending
    await upgradeNotifier.load(forceRefresh: true);
    expect(upgradeNotifier.state.snapshot?.eligibleForUpgrade, isTrue);
    final upgDraft = await upgradeNotifier.startUpgrade(
      businessName: 'Karim Premier Office',
      commercialRegisterNumber: 'CR-998877',
      businessType: BusinessAccountType.office,
    );
    expect(upgDraft?.accountId, repo.accountId);

    for (final req in upgradeNotifier.state.snapshot!.businessRequirements) {
      await docNotifier.uploadPickedFile(
        requirement: req,
        file: PickedDocumentFile(
          fileName: '${req.documentType}.pdf',
          mimeType: 'application/pdf',
          bytes: Uint8List.fromList('%PDF-1.7\n'.codeUnits),
        ),
        isArabic: false,
      );
    }
    await upgradeNotifier.submitUpgrade();
    // Still IDENTITY_VERIFIED while upgrade is PENDING
    await trackNotifier.refresh();
    expect(trackNotifier.state.snapshot?.verificationTier, VerificationTier.identityVerified);

    // 6. Admin approves upgrade -> BUSINESS_VERIFIED, single account preserved
    repo.simulateAdminApproveUpgrade();
    await trackNotifier.refresh();
    expect(repo.createdAccountsCount, 1);
    expect(trackNotifier.state.snapshot?.verificationTier, VerificationTier.businessVerified);
    expect(trackNotifier.state.snapshot?.activeBadge?.label, 'شركة / مكتب موثق');

    // 7. Admin suspends -> active badge removed immediately
    repo.simulateAdminSuspend('Compliance hold');
    await trackNotifier.refresh();
    expect(trackNotifier.state.snapshot?.sellerStatus, VerificationStatus.suspended);
    expect(trackNotifier.state.snapshot?.activeBadge, isNull);
  });
}
