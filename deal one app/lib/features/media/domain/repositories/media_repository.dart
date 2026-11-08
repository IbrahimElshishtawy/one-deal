import 'dart:typed_data';
import 'package:market_space/features/media/domain/entities/media_upload_target.dart';

abstract class MediaRepository {
  /// Requests presigned upload URLs from backend for specified MIME types
  Future<List<MediaUploadTarget>> requestUploadUrls(List<String> contentTypes);

  /// Directly uploads binary image bytes to the storage target URL without sending bearer auth
  Future<void> uploadBinary(String uploadUrl, Uint8List fileBytes, String contentType);
}
