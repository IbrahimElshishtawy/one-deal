class MediaUploadTarget {
  final String storageKey;
  final String uploadUrl;
  final String publicUrl;
  final String contentType;

  const MediaUploadTarget({
    required this.storageKey,
    required this.uploadUrl,
    required this.publicUrl,
    required this.contentType,
  });
}
