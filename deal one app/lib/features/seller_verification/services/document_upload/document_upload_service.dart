import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/repositories/seller_verification_repository.dart';

/// Orchestrates the 3-step secure private document upload flow:
/// 1. Request short-lived presigned PUT URL (`POST /seller-applications/me/documents/upload-url`).
/// 2. Upload binary bytes directly to private object storage (with progress & cancel support).
/// 3. Confirm/attach or replace document (`POST /me/documents` or `PUT /me/documents/:id/replace`)
///    with base64 magic-byte header for server content signature verification.
class DocumentUploadService {
  final SellerVerificationRepository repository;

  const DocumentUploadService({required this.repository});

  Future<SellerDocumentEntity> uploadDocument({
    required String documentType,
    required PickedDocumentFile file,
    String? requirementId,
    String? replaceDocumentId,
    String? expiresAt,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    onProgress?.call(0.05);

    // Step 1: Request private presigned upload target
    final target = await repository.requestDocumentUploadUrl(
      documentType: documentType,
      fileName: file.fileName,
      mimeType: file.mimeType,
      fileSizeBytes: file.sizeBytes,
    );

    onProgress?.call(0.15);

    // Step 2: Upload binary directly to private storage
    await repository.uploadDocumentBinary(
      uploadUrl: target.uploadUrl,
      file: file,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total > 0) {
          final ratio = (sent / total).clamp(0.0, 1.0);
          onProgress?.call(0.15 + (ratio * 0.70));
        }
      },
    );

    onProgress?.call(0.90);

    // Step 3: Extract first 16 bytes for magic-byte MIME verification on backend
    final headerLen = math.min(16, file.bytes.length);
    final fileHeaderBase64 = headerLen >= 4
        ? base64Encode(file.bytes.sublist(0, headerLen))
        : null;

    final confirmed = replaceDocumentId != null && replaceDocumentId.isNotEmpty
        ? await repository.replaceDocument(
            documentId: replaceDocumentId,
            storageKey: target.storageKey,
            originalFileName: file.fileName,
            mimeType: file.mimeType,
            fileSizeBytes: file.sizeBytes,
            fileHeaderBase64: fileHeaderBase64,
            expiresAt: expiresAt,
          )
        : await repository.confirmDocument(
            documentType: documentType,
            storageKey: target.storageKey,
            originalFileName: file.fileName,
            mimeType: file.mimeType,
            fileSizeBytes: file.sizeBytes,
            fileHeaderBase64: fileHeaderBase64,
            expiresAt: expiresAt,
            requirementId: requirementId ?? target.requirementId,
          );

    onProgress?.call(1.0);
    return confirmed;
  }
}
