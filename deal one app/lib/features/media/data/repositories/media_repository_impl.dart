import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/media/data/dto/presigned_upload_dto.dart';
import 'package:market_space/features/media/data/mappers/media_mapper.dart';
import 'package:market_space/features/media/domain/entities/media_upload_target.dart';
import 'package:market_space/features/media/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final ApiClient apiClient;
  final Dio rawBinaryUploader;

  MediaRepositoryImpl({
    required this.apiClient,
    Dio? rawBinaryUploader,
  }) : rawBinaryUploader = rawBinaryUploader ?? Dio();

  @override
  Future<List<MediaUploadTarget>> requestUploadUrls(List<String> contentTypes) async {
    final response = await apiClient.post(
      ApiEndpoints.imageUploadUrls,
      data: PresignedUploadRequestDto(contentTypes: contentTypes).toJson(),
    );

    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    }

    final dtos = items
        .map((e) => PresignedTargetDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return dtos.map(MediaMapper.toTargetEntity).toList();
  }

  @override
  Future<void> uploadBinary(String uploadUrl, Uint8List fileBytes, String contentType) async {
    // SECURITY INVARIANT: Do not send backend bearer tokens to third-party storage hosts (R2/S3)
    await rawBinaryUploader.put(
      uploadUrl,
      data: fileBytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileBytes.length.toString(),
        },
      ),
    );
  }
}
