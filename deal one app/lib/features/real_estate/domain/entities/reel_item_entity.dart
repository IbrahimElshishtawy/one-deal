class ReelItemEntity {
  final String listingId;
  final String title;
  final double price;
  final String currency;
  final String cityName;
  final String governorateName;
  final String? videoHlsUrl;
  final String? videoStreamUid;
  final String? posterImageUrl;
  final String sellerName;
  final String? sellerAvatarUrl;
  final DateTime? refreshedAt;
  final int favoritesCount;
  final Map<String, dynamic> attributes;

  const ReelItemEntity({
    required this.listingId,
    required this.title,
    required this.price,
    this.currency = 'EGP',
    required this.cityName,
    required this.governorateName,
    this.videoHlsUrl,
    this.videoStreamUid,
    this.posterImageUrl,
    required this.sellerName,
    this.sellerAvatarUrl,
    this.refreshedAt,
    this.favoritesCount = 0,
    this.attributes = const {},
  });

  String get locationDisplay {
    if (cityName.isNotEmpty && governorateName.isNotEmpty) {
      return '$cityName، $governorateName';
    }
    return cityName.isNotEmpty ? cityName : governorateName;
  }

  /// Derives a Cloudflare Stream thumbnail URL when streamUid is available
  /// and no explicit posterImageUrl was returned.
  String? get effectivePosterUrl {
    if (posterImageUrl != null && posterImageUrl!.isNotEmpty) {
      return posterImageUrl;
    }
    if (videoHlsUrl != null &&
        videoHlsUrl!.isNotEmpty &&
        !videoHlsUrl!.endsWith('.m3u8')) {
      return videoHlsUrl;
    }
    if (videoStreamUid != null && videoStreamUid!.isNotEmpty) {
      return 'https://videodelivery.net/$videoStreamUid/thumbnails/thumbnail.jpg';
    }
    return null;
  }
}

class ReelsFeedPageResult {
  final List<ReelItemEntity> items;
  final String? nextCursor;

  const ReelsFeedPageResult({
    required this.items,
    this.nextCursor,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
