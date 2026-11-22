import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';

abstract class ReelsRepository {
  Future<ReelsFeedPageResult> getVideoFeed({String? cursor, int limit = 10});
}

class ReelsRepositoryImpl implements ReelsRepository {
  final ApiClient apiClient;

  const ReelsRepositoryImpl({required this.apiClient});

  @override
  Future<ReelsFeedPageResult> getVideoFeed({
    String? cursor,
    int limit = 10,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.videoFeed,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    final raw = response.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(
            raw['data'] is Map ? raw['data'] as Map : raw,
          )
        : <String, dynamic>{};

    final rawItems = map['items'] is List ? map['items'] as List : const [];
    final items = rawItems
        .whereType<Map>()
        .map((e) => _parseReel(Map<String, dynamic>.from(e)))
        .toList();

    return ReelsFeedPageResult(
      items: items,
      nextCursor: map['nextCursor']?.toString(),
    );
  }

  ReelItemEntity _parseReel(Map<String, dynamic> json) {
    final seller = json['seller'] is Map
        ? Map<String, dynamic>.from(json['seller'] as Map)
        : const <String, dynamic>{};
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);

    return ReelItemEntity(
      listingId: json['listingId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: price,
      currency: json['currency']?.toString() ?? 'EGP',
      cityName: json['cityName']?.toString() ?? '',
      governorateName: json['governorateName']?.toString() ?? '',
      videoHlsUrl: json['videoHlsUrl']?.toString(),
      videoStreamUid: json['videoStreamUid']?.toString(),
      posterImageUrl: json['posterImageUrl']?.toString() ??
          json['imageUrl']?.toString(),
      sellerName: seller['fullName']?.toString() ??
          json['sellerName']?.toString() ??
          'Deal One',
      sellerAvatarUrl: seller['avatarUrl']?.toString(),
      refreshedAt: json['refreshedAt'] != null
          ? DateTime.tryParse(json['refreshedAt'].toString())
          : null,
      favoritesCount: (json['favoritesCount'] as num?)?.toInt() ?? 0,
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
    );
  }
}
