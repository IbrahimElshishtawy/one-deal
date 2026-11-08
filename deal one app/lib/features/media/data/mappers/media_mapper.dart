import 'package:market_space/features/media/data/dto/presigned_upload_dto.dart';
import 'package:market_space/features/media/domain/entities/media_upload_target.dart';

class MediaMapper {
  static MediaUploadTarget toTargetEntity(PresignedTargetDto dto) {
    return MediaUploadTarget(
      storageKey: dto.key,
      uploadUrl: dto.uploadUrl,
      publicUrl: dto.publicUrl,
      contentType: dto.contentType,
    );
  }
}
