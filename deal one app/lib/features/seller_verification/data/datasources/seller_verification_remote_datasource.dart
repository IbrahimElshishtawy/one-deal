import 'package:dio/dio.dart';
import 'package:market_space/core/errors/error_mapper.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/seller_verification/data/models/seller_verification_models.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';

/// Remote datasource communicating exclusively with Deal One's real backend API
/// via the centralized [ApiClient].
class SellerVerificationRemoteDataSource {
  final ApiClient apiClient;
  final Dio rawBinaryUploader;

  SellerVerificationRemoteDataSource({
    required this.apiClient,
    Dio? rawBinaryUploader,
  }) : rawBinaryUploader = rawBinaryUploader ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  Map<String, dynamic> _unwrapDataMap(dynamic raw) {
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  Future<List<SellerVerificationRequirementEntity>> fetchRequirements({
    required SellerType sellerType,
    List<String> marketplaceSections = const [],
  }) async {
    final query = <String, dynamic>{
      'sellerType': sellerType.apiValue,
      if (marketplaceSections.isNotEmpty)
        'marketplaceSections': marketplaceSections.join(','),
    };

    final response = await apiClient.get<dynamic>(
      ApiEndpoints.sellerApplicationRequirements,
      queryParameters: query,
    );

    final data = _unwrapDataMap(response.data);
    final rawList = data['requirements'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map(
          (e) => SellerVerificationRequirementModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);
  }

  Future<VerificationStatusSnapshot> fetchMyVerificationStatus() async {
    final response = await apiClient.get<dynamic>(
      ApiEndpoints.sellerApplicationMe,
    );
    return VerificationStatusModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<List<VerificationHistoryItemEntity>> fetchMyHistory() async {
    final response = await apiClient.get<dynamic>(
      ApiEndpoints.sellerApplicationMeHistory,
    );
    final data = _unwrapDataMap(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (e) => VerificationHistoryItemModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);
  }

  Future<SellerApplicationEntity> createApplication(
    Map<String, dynamic> payload,
  ) async {
    final sanitized = _stripServerControlledFields(payload);
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplications,
      data: sanitized,
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> updateDraft(
    Map<String, dynamic> payload,
  ) async {
    final sanitized = _stripServerControlledFields(payload);
    final response = await apiClient.patch<dynamic>(
      ApiEndpoints.sellerApplicationMe,
      data: sanitized,
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<PrivateUploadTargetEntity> requestDocumentUploadUrl({
    required String documentType,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
  }) async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeDocumentUploadUrl,
      data: {
        'documentType': documentType,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
      },
    );
    return PrivateUploadTargetModel.fromJson(_unwrapDataMap(response.data));
  }

  /// Uploads raw binary bytes directly to the short-lived private presigned URL.
  /// Security invariant: NEVER attaches Deal One bearer tokens to storage hosts.
  Future<void> uploadBinaryToPrivateStorage({
    required String uploadUrl,
    required PickedDocumentFile file,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    // Support local dev fallback URLs gracefully in non-R2 environments
    final uri = Uri.tryParse(uploadUrl);
    if (uri != null && uri.host.endsWith('.deal-one.local')) {
      onSendProgress?.call(file.sizeBytes, file.sizeBytes);
      return;
    }

    try {
      await rawBinaryUploader.put<dynamic>(
        uploadUrl,
        data: Stream.fromIterable([file.bytes]),
        options: Options(
          headers: {
            'Content-Type': file.mimeType,
            'Content-Length': file.sizeBytes.toString(),
          },
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

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
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeDocuments,
      data: {
        'documentType': documentType,
        'storageKey': storageKey,
        'originalFileName': originalFileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        if (fileHeaderBase64 != null && fileHeaderBase64.isNotEmpty)
          'fileHeaderBase64': fileHeaderBase64,
        if (expiresAt != null && expiresAt.isNotEmpty) 'expiresAt': expiresAt,
        if (requirementId != null && requirementId.isNotEmpty)
          'requirementId': requirementId,
      },
    );
    return SellerDocumentModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerDocumentEntity> replaceDocument({
    required String documentId,
    required String storageKey,
    required String originalFileName,
    required String mimeType,
    required int fileSizeBytes,
    String? fileHeaderBase64,
    String? expiresAt,
  }) async {
    final response = await apiClient.put<dynamic>(
      ApiEndpoints.sellerApplicationMeDocumentReplace(documentId),
      data: {
        'storageKey': storageKey,
        'originalFileName': originalFileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        if (fileHeaderBase64 != null && fileHeaderBase64.isNotEmpty)
          'fileHeaderBase64': fileHeaderBase64,
        if (expiresAt != null && expiresAt.isNotEmpty) 'expiresAt': expiresAt,
      },
    );
    return SellerDocumentModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<void> deleteDocument(String documentId) async {
    await apiClient.delete<dynamic>(
      ApiEndpoints.sellerApplicationMeDocumentDelete(documentId),
    );
  }

  Future<SellerApplicationEntity> submitApplication() async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeSubmit,
      data: const <String, dynamic>{},
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<VerificationStatusSnapshot> devApproveMyApplication() async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeDevApprove,
      data: const <String, dynamic>{},
    );
    return VerificationStatusModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> resubmitApplication(
    Map<String, dynamic> payload,
  ) async {
    final sanitized = _stripServerControlledFields(payload);
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeResubmit,
      data: sanitized,
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> withdrawApplication({
    String? reason,
    String? applicationType,
  }) async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeWithdraw,
      data: <String, dynamic>{
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (applicationType != null && applicationType.trim().isNotEmpty)
          'applicationType': applicationType.trim(),
      },
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> startVerificationRenewal({
    bool reuseValidDocuments = true,
    String? notes,
  }) async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerApplicationMeRenew,
      data: <String, dynamic>{
        'reuseValidDocuments': reuseValidDocuments,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<BusinessUpgradeSnapshot> fetchBusinessUpgradeStatus() async {
    final response = await apiClient.get<dynamic>(
      ApiEndpoints.sellerBusinessUpgrade,
    );
    return BusinessUpgradeModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> createBusinessUpgrade(
    Map<String, dynamic> payload,
  ) async {
    final sanitized = _stripServerControlledFields(payload);
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerBusinessUpgrade,
      data: sanitized,
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> submitBusinessUpgrade() async {
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerBusinessUpgradeSubmit,
      data: const <String, dynamic>{},
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  Future<SellerApplicationEntity> resubmitBusinessUpgrade(
    Map<String, dynamic> payload,
  ) async {
    final sanitized = _stripServerControlledFields(payload);
    final response = await apiClient.post<dynamic>(
      ApiEndpoints.sellerBusinessUpgradeResubmit,
      data: sanitized,
    );
    return SellerApplicationModel.fromJson(_unwrapDataMap(response.data));
  }

  /// Defense-in-depth: never send server-authoritative fields from the mobile client.
  Map<String, dynamic> _stripServerControlledFields(
    Map<String, dynamic> payload,
  ) {
    final copy = Map<String, dynamic>.from(payload);
    copy.remove('verificationTier');
    copy.remove('verificationStatus');
    copy.remove('derivedVerificationTier');
    copy.remove('sellerStatus');
    return copy;
  }
}
