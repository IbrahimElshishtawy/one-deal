import 'dart:io';

import 'package:flutter/services.dart';
import 'package:market_space/core/errors/app_failure.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/validators/seller_verification_validators.dart';

enum DocumentPickSource {
  camera,
  gallery,
  file,
}

/// Abstract document picker service supporting camera, gallery, and PDF/file selection.
/// Easily overridable in Riverpod for native plugin integration or automated tests.
abstract class DocumentPickerService {
  Future<PickedDocumentFile?> pickDocument(DocumentPickSource source);

  Future<PickedDocumentFile> readFromFilePath(String path);
}

class PlatformDocumentPickerService implements DocumentPickerService {
  static const MethodChannel _channel = MethodChannel(
    'com.dealone.market_space/document_picker',
  );

  const PlatformDocumentPickerService();

  @override
  Future<PickedDocumentFile?> pickDocument(DocumentPickSource source) async {
    try {
      final method = switch (source) {
        DocumentPickSource.camera => 'pickFromCamera',
        DocumentPickSource.gallery => 'pickFromGallery',
        DocumentPickSource.file => 'pickFile',
      };

      final result = await _channel.invokeMapMethod<String, dynamic>(
        method,
        const {
          'allowedMimeTypes': [
            'application/pdf',
            'image/jpeg',
            'image/png',
            'image/webp',
          ],
        },
      );

      if (result == null) return null;

      final path = result['path']?.toString();
      final rawBytes = result['bytes'];
      final fileName = result['fileName']?.toString() ?? 'document.jpg';
      final mimeType = result['mimeType']?.toString() ??
          SellerVerificationValidators.inferMimeType(fileName) ??
          'image/jpeg';

      if (rawBytes is Uint8List) {
        return PickedDocumentFile(
          fileName: fileName,
          mimeType: mimeType,
          bytes: rawBytes,
        );
      }

      if (path != null && path.isNotEmpty) {
        return readFromFilePath(path);
      }

      return null;
    } on MissingPluginException {
      throw const UnsupportedFeatureFailure(
        userFriendlyMessage:
            'Native document picker is not linked on this platform build. Please select a document from a supported mobile device.',
        technicalCode: 'DOCUMENT_PICKER_UNAVAILABLE',
      );
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains('permission') ||
          e.code.toLowerCase().contains('denied')) {
        throw ForbiddenFailure(
          userFriendlyMessage: e.message ??
              'Camera or storage permission is required to select verification documents.',
          technicalCode: 'PICKER_PERMISSION_DENIED',
        );
      }
      throw UnknownFailure(
        userFriendlyMessage:
            e.message ?? 'Unable to select document. Please try again.',
        technicalCode: e.code,
      );
    }
  }

  @override
  Future<PickedDocumentFile> readFromFilePath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const NotFoundFailure(
        userFriendlyMessage: 'Selected file could not be found on device.',
        technicalCode: 'FILE_NOT_FOUND',
      );
    }
    final bytes = await file.readAsBytes();
    final segments = path.replaceAll('\\', '/').split('/');
    final fileName = segments.isNotEmpty ? segments.last : 'document.jpg';
    final mimeType =
        SellerVerificationValidators.inferMimeType(fileName) ?? 'image/jpeg';

    return PickedDocumentFile(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
    );
  }
}
