import 'package:dio/dio.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Domain repository contract for Seller Verification & Business Upgrade.
abstract class SellerVerificationRepository {
  Future<List<SellerVerificationRequirementEntity>> getRequirements({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
    bool forceRefresh = false,
  });

  Future<VerificationStatusSnapshot> getMyVerificationStatus({
    bool forceRefresh = false,
  });

  Future<List<VerificationHistoryItemEntity>> getMyHistory();

  Future<SellerApplicationEntity> createApplication(
    Map<String, dynamic> payload,
  );

  Future<SellerApplicationEntity> updateDraft(
    Map<String, dynamic> payload,
  );

  Future<PrivateUploadTargetEntity> requestDocumentUploadUrl({
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  });

  Future<void> uploadDocumentBinary({
    required String uploadUrl,
    required PickedDocumentFile file,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  });

  Future<SellerDocumentEntity> confirmDocument({
    required String documentType,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
    String? requirementId,
  });

  Future<SellerDocumentEntity> replaceDocument({
    required String documentId,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
  });

  Future<void> deleteDocument(String documentId);

  Future<SellerApplicationEntity> submitApplication();

  Future<SellerApplicationEntity> resubmitApplication(
    Map<String, dynamic> payload,
  );

  Future<BusinessUpgradeSnapshot> getBusinessUpgradeStatus({
    bool forceRefresh = false,
  });

  Future<SellerApplicationEntity> createBusinessUpgrade(
    Map<String, dynamic> payload,
  );

  Future<SellerApplicationEntity> submitBusinessUpgrade();

  Future<SellerApplicationEntity> resubmitBusinessUpgrade(
    Map<String, dynamic> payload,
  );
}
