class PresignedUploadRequestDto {
  final List<String> contentTypes;

  const PresignedUploadRequestDto({required this.contentTypes});

  Map<String, dynamic> toJson() => {'contentTypes': contentTypes};
}

class PresignedTargetDto {
  final String key;
  final String uploadUrl;
  final String publicUrl;
  final String contentType;

  const PresignedTargetDto({
    required this.key,
    required this.uploadUrl,
    required this.publicUrl,
    required this.contentType,
  });

  factory PresignedTargetDto.fromJson(Map<String, dynamic> json) {
    return PresignedTargetDto(
      key: json['key']?.toString() ?? '',
      uploadUrl: json['uploadUrl']?.toString() ?? json['upload_url']?.toString() ?? '',
      publicUrl: json['publicUrl']?.toString() ?? json['public_url']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? json['content_type']?.toString() ?? 'image/jpeg',
    );
  }
}
