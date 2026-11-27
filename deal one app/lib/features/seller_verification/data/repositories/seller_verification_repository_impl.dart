import 'package:dio/dio.dart';
import 'package:market_space/core/cache/hybrid_cache_manager.dart';
import 'package:market_space/features/seller_verification/data/datasources/seller_verification_remote_datasource.dart';
import 'package:market_space/features/seller_verification/data/models/seller_verification_models.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';

/// Repository implementation with hybrid caching strictly for non-sensitive
/// configuration (document requirements) and immediate invalidation on mutations.
/// Never caches private document URLs, raw identity numbers, or authoritative approvals.
class SellerVerificationRepositoryImpl implements SellerVerificationRepository {
  final SellerVerificationRemoteDataSource remoteDataSource;
  final HybridCacheManager? cache;

  static const Duration _requirementsTtl = Duration(minutes: 15);

  SellerVerificationRepositoryImpl({
    required this.remoteDataSource,
    this.cache,
  });

  String _requirementsCacheKey(
    SellerType sellerType,
    List<String> sections,
  ) {
    final sorted = [...sections]..sort();
    return 'sv_reqs_${sellerType.apiValue}_${sorted.join('_')}';
  }

  @override
  Future<List<SellerVerificationRequirementEntity>> getRequirements({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
    bool forceRefresh = false,
  }) async {
    final key = _requirementsCacheKey(sellerType, marketplaceSections);

    if (!forceRefresh && cache != null) {
      final cached = await cache!.read(key);
      if (cached != null && cached.isFresh) {
        final items = cached.payload['items'];
        if (items is List && items.isNotEmpty) {
          return items
              .whereType<Map>()
              .map(
                (m) => SellerVerificationRequirementModel.fromJson(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList(growable: false);
        }
      }
    }

    final fresh = await remoteDataSource.fetchRequirements(
      sellerType: sellerType,
      marketplaceSections: marketplaceSections,
    );

    if (cache != null && fresh.isNotEmpty) {
      await cache!.write(
        key,
        {
          'items': fresh
              .map(SellerVerificationRequirementModel.toJson)
              .toList(growable: false),
        },
        ttl: _requirementsTtl,
      );
    }

    return fresh;
  }

  @override
  Future<VerificationStatusSnapshot> getMyVerificationStatus({
    bool forceRefresh = false,
  }) {
    // Always fetch authoritative verification status from the server.
    return remoteDataSource.fetchMyVerificationStatus();
  }

  @override
  Future<List<VerificationHistoryItemEntity>> getMyHistory() {
    return remoteDataSource.fetchMyHistory();
  }

  @override
  Future<SellerApplicationEntity> createApplication(
    Map<String, dynamic> payload,
  ) {
    return remoteDataSource.createApplication(payload);
  }

  @override
  Future<SellerApplicationEntity> updateDraft(Map<String, dynamic> payload) {
    return remoteDataSource.updateDraft(payload);
  }

  @override
  Future<PrivateUploadTargetEntity> requestDocumentUploadUrl({
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) {
    return remoteDataSource.requestDocumentUploadUrl(
      documentType: documentType,
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
    );
  }

  @override
  Future<void> uploadDocumentBinary({
    required String uploadUrl,
    required PickedDocumentFile file,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return remoteDataSource.uploadBinaryToPrivateStorage(
      uploadUrl: uploadUrl,
      file: file,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
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
  }) {
    return remoteDataSource.confirmDocument(
      documentType: documentType,
      storageKey: storageKey,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      fileHeaderBase64: fileHeaderBase64,
      expiresAt: expiresAt,
      requirementId: requirementId,
    );
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
  }) {
    return remoteDataSource.replaceDocument(
      documentId: documentId,
      storageKey: storageKey,
      originalFileName: originalFileName,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      fileHeaderBase64: fileHeaderBase64,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> deleteDocument(String documentId) {
    return remoteDataSource.deleteDocument(documentId);
  }

  @override
  Future<SellerApplicationEntity> submitApplication() {
    return remoteDataSource.submitApplication();
  }

  @override
  Future<VerificationStatusSnapshot> devApproveMyApplication() {
    return remoteDataSource.devApproveMyApplication();
  }

  @override
  Future<SellerApplicationEntity> resubmitApplication(
    Map<String, dynamic> payload,
  ) {
    return remoteDataSource.resubmitApplication(payload);
  }

  @override
  Future<SellerApplicationEntity> withdrawApplication({
    String? reason,
    String? applicationType,
  }) {
    return remoteDataSource.withdrawApplication(
      reason: reason,
      applicationType: applicationType,
    );
  }

  @override
  Future<SellerApplicationEntity> startVerificationRenewal({
    bool reuseValidDocuments = true,
    String? notes,
  }) {
    return remoteDataSource.startVerificationRenewal(
      reuseValidDocuments: reuseValidDocuments,
      notes: notes,
    );
  }

  @override
  Future<BusinessUpgradeSnapshot> getBusinessUpgradeStatus({
    bool forceRefresh = false,
  }) {
    return remoteDataSource.fetchBusinessUpgradeStatus();
  }

  @override
  Future<SellerApplicationEntity> createBusinessUpgrade(
    Map<String, dynamic> payload,
  ) {
    return remoteDataSource.createBusinessUpgrade(payload);
  }

  @override
  Future<SellerApplicationEntity> submitBusinessUpgrade() {
    return remoteDataSource.submitBusinessUpgrade();
  }

  @override
  Future<SellerApplicationEntity> resubmitBusinessUpgrade(
    Map<String, dynamic> payload,
  ) {
    return remoteDataSource.resubmitBusinessUpgrade(payload);
  }
}
