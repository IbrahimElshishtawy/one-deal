enum SellerDealStatus {
  newInquiry('NEW_INQUIRY', 'استفسار جديد', 'New Inquiry'),
  contacted('CONTACTED', 'تم التواصل', 'Contacted'),
  negotiating('NEGOTIATING', 'قيد التفاوض', 'Negotiating'),
  agreed('AGREED', 'تم الاتفاق', 'Agreed'),
  completed('COMPLETED', 'مكتمل (بتأكيد البائع)', 'Completed (Seller-Reported)'),
  cancelled('CANCELLED', 'ملغي', 'Cancelled');

  final String apiValue;
  final String labelAr;
  final String labelEn;

  const SellerDealStatus(this.apiValue, this.labelAr, this.labelEn);

  String label({required bool isArabic}) => isArabic ? labelAr : labelEn;

  static SellerDealStatus fromApi(String? raw) {
    final upper = (raw ?? '').trim().toUpperCase();
    for (final s in values) {
      if (s.apiValue == upper) return s;
    }
    return SellerDealStatus.newInquiry;
  }
}

class SellerDashboardSummaryEntity {
  final int totalAds;
  final int activeAds;
  final int totalViews;
  final int totalFavorites;
  final int totalContacts;
  final int totalConversations;
  final int unreadConversations;
  final int pendingInquiries;
  final int completedDealsCount;
  final int totalDealsCount;

  const SellerDashboardSummaryEntity({
    required this.totalAds,
    required this.activeAds,
    required this.totalViews,
    required this.totalFavorites,
    required this.totalContacts,
    required this.totalConversations,
    required this.unreadConversations,
    required this.pendingInquiries,
    required this.completedDealsCount,
    required this.totalDealsCount,
  });

  factory SellerDashboardSummaryEntity.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;
    return SellerDashboardSummaryEntity(
      totalAds: n('totalAds'),
      activeAds: n('activeAds'),
      totalViews: n('totalViews'),
      totalFavorites: n('totalFavorites'),
      totalContacts: n('totalContacts'),
      totalConversations: n('totalConversations'),
      unreadConversations: n('unreadConversations'),
      pendingInquiries: n('pendingInquiries'),
      completedDealsCount: n('completedDealsCount'),
      totalDealsCount: n('totalDealsCount'),
    );
  }
}

class SellerListingItemEntity {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String listingKind;
  final String moderationStatus;
  final String publicationStatus;
  final String availabilityStatus;
  final String categorySlug;
  final String categoryNameAr;
  final String categoryNameEn;
  final String? thumbnailUrl;
  final int viewsCount;
  final int favoritesCount;
  final int contactRevealsCount;
  final int inquiriesCount;
  final DateTime? updatedAt;

  const SellerListingItemEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.listingKind,
    required this.moderationStatus,
    required this.publicationStatus,
    required this.availabilityStatus,
    required this.categorySlug,
    required this.categoryNameAr,
    required this.categoryNameEn,
    this.thumbnailUrl,
    required this.viewsCount,
    required this.favoritesCount,
    required this.contactRevealsCount,
    required this.inquiriesCount,
    this.updatedAt,
  });

  factory SellerListingItemEntity.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : (double.tryParse(rawPrice?.toString() ?? '') ?? 0.0);
    return SellerListingItemEntity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: price,
      currency: json['currency']?.toString() ?? 'EGP',
      listingKind: json['listingKind']?.toString() ?? 'sale',
      moderationStatus: json['moderationStatus']?.toString() ?? 'approved',
      publicationStatus: json['publicationStatus']?.toString() ?? 'published',
      availabilityStatus: json['availabilityStatus']?.toString() ?? 'available',
      categorySlug: json['categorySlug']?.toString() ?? '',
      categoryNameAr: json['categoryNameAr']?.toString() ?? '',
      categoryNameEn: json['categoryNameEn']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      viewsCount: n('viewsCount'),
      favoritesCount: n('favoritesCount'),
      contactRevealsCount: n('contactRevealsCount'),
      inquiriesCount: n('inquiriesCount'),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class SellerInboxConversationEntity {
  final String id;
  final String listingId;
  final String listingTitle;
  final double listingPrice;
  final String? listingThumbnailUrl;
  final String customerUserId;
  final String customerName;
  final String? customerAvatarUrl;
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const SellerInboxConversationEntity({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingPrice,
    this.listingThumbnailUrl,
    required this.customerUserId,
    required this.customerName,
    this.customerAvatarUrl,
    required this.lastMessageText,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory SellerInboxConversationEntity.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['listingPrice'];
    return SellerInboxConversationEntity(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? '',
      listingTitle: json['listingTitle']?.toString() ?? '',
      listingPrice: rawPrice is num ? rawPrice.toDouble() : 0.0,
      listingThumbnailUrl: json['listingThumbnailUrl']?.toString(),
      customerUserId: json['customerUserId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerAvatarUrl: json['customerAvatarUrl']?.toString(),
      lastMessageText: json['lastMessageText']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? ''),
      unreadCount: (json['unreadCount'] is num)
          ? (json['unreadCount'] as num).toInt()
          : 0,
    );
  }
}

class SellerActivityItemEntity {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime? timestamp;

  const SellerActivityItemEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.timestamp,
  });

  factory SellerActivityItemEntity.fromJson(Map<String, dynamic> json) {
    return SellerActivityItemEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'activity',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }
}

class SellerDashboardEntity {
  final SellerDashboardSummaryEntity summary;
  final List<SellerListingItemEntity> topListings;
  final List<SellerInboxConversationEntity> recentConversations;
  final List<SellerActivityItemEntity> recentActivities;
  final bool hasDedicatedSocialPosts;
  final bool v1SalesCrmSellerReportedOnly;

  const SellerDashboardEntity({
    required this.summary,
    required this.topListings,
    required this.recentConversations,
    required this.recentActivities,
    this.hasDedicatedSocialPosts = false,
    this.v1SalesCrmSellerReportedOnly = true,
  });

  factory SellerDashboardEntity.fromJson(Map<String, dynamic> json) {
    final caps = json['capabilities'] is Map
        ? Map<String, dynamic>.from(json['capabilities'] as Map)
        : const <String, dynamic>{};
    return SellerDashboardEntity(
      summary: SellerDashboardSummaryEntity.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : const {},
      ),
      topListings: (json['topListings'] is List)
          ? (json['topListings'] as List)
              .whereType<Map>()
              .map((m) => SellerListingItemEntity.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
      recentConversations: (json['recentConversations'] is List)
          ? (json['recentConversations'] as List)
              .whereType<Map>()
              .map((m) => SellerInboxConversationEntity.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
      recentActivities: (json['recentActivities'] is List)
          ? (json['recentActivities'] as List)
              .whereType<Map>()
              .map((m) => SellerActivityItemEntity.fromJson(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
      hasDedicatedSocialPosts: caps['hasDedicatedSocialPosts'] == true,
      v1SalesCrmSellerReportedOnly:
          caps['v1SalesCrmSellerReportedOnly'] != false,
    );
  }
}

class SellerInteractionItemEntity {
  final String id;
  final String type;
  final String? listingId;
  final String listingTitle;
  final String actorName;
  final String summary;
  final DateTime? createdAt;

  const SellerInteractionItemEntity({
    required this.id,
    required this.type,
    this.listingId,
    required this.listingTitle,
    required this.actorName,
    required this.summary,
    this.createdAt,
  });

  factory SellerInteractionItemEntity.fromJson(Map<String, dynamic> json) {
    return SellerInteractionItemEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'inquiry',
      listingId: json['listingId']?.toString(),
      listingTitle: json['listingTitle']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? 'Customer',
      summary: json['summary']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class SellerInteractionsResultEntity {
  final int views;
  final int contactRequests;
  final int favorites;
  final int inquiries;
  final int bookings;
  final List<SellerInteractionItemEntity> items;
  final int total;

  const SellerInteractionsResultEntity({
    required this.views,
    required this.contactRequests,
    required this.favorites,
    required this.inquiries,
    required this.bookings,
    required this.items,
    required this.total,
  });

  factory SellerInteractionsResultEntity.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : const <String, dynamic>{};
    int n(String k) => (s[k] is num) ? (s[k] as num).toInt() : 0;
    final list = (json['items'] is List)
        ? (json['items'] as List)
            .whereType<Map>()
            .map((m) => SellerInteractionItemEntity.fromJson(
                  Map<String, dynamic>.from(m),
                ))
            .toList()
        : const <SellerInteractionItemEntity>[];
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};
    return SellerInteractionsResultEntity(
      views: n('views'),
      contactRequests: n('contactRequests'),
      favorites: n('favorites'),
      inquiries: n('inquiries'),
      bookings: n('bookings'),
      items: list,
      total: (meta['total'] is num) ? (meta['total'] as num).toInt() : list.length,
    );
  }
}

class SellerDealEntity {
  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingThumbnailUrl;
  final String customerName;
  final String? customerReference;
  final double initialPrice;
  final double? agreedPrice;
  final String currency;
  final SellerDealStatus status;
  final bool sellerReportedOnly;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerDealEntity({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    this.listingThumbnailUrl,
    required this.customerName,
    this.customerReference,
    required this.initialPrice,
    this.agreedPrice,
    required this.currency,
    required this.status,
    this.sellerReportedOnly = true,
    this.notes,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerDealEntity.fromJson(Map<String, dynamic> json) {
    double? d(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    return SellerDealEntity(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? '',
      listingTitle: json['listingTitle']?.toString() ?? '',
      listingThumbnailUrl: json['listingThumbnailUrl']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerReference: json['customerReference']?.toString(),
      initialPrice: d(json['initialPrice']) ?? 0.0,
      agreedPrice: d(json['agreedPrice']),
      currency: json['currency']?.toString() ?? 'EGP',
      status: SellerDealStatus.fromApi(json['status']?.toString()),
      sellerReportedOnly: json['sellerReportedOnly'] != false,
      notes: json['notes']?.toString(),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class SellerDailyPoint {
  final String date;
  final int inquiries;
  final int deals;

  const SellerDailyPoint({
    required this.date,
    required this.inquiries,
    required this.deals,
  });

  factory SellerDailyPoint.fromJson(Map<String, dynamic> json) {
    int n(String k) => (json[k] is num) ? (json[k] as num).toInt() : 0;
    return SellerDailyPoint(
      date: json['date']?.toString() ?? '',
      inquiries: n('inquiries'),
      deals: n('deals'),
    );
  }
}

class SellerAnalyticsEntity {
  final String range;
  final int totalAds;
  final int activeAds;
  final int totalViews;
  final int totalFavorites;
  final int customerInquiries;
  final int conversationsCount;
  final int completedSellerReportedDeals;
  final int responseRatePercent;
  final List<SellerListingItemEntity> topPerformingAds;
  final List<SellerDailyPoint> dailySeries;

  const SellerAnalyticsEntity({
    required this.range,
    required this.totalAds,
    required this.activeAds,
    required this.totalViews,
    required this.totalFavorites,
    required this.customerInquiries,
    required this.conversationsCount,
    required this.completedSellerReportedDeals,
    required this.responseRatePercent,
    required this.topPerformingAds,
    required this.dailySeries,
  });

  factory SellerAnalyticsEntity.fromJson(Map<String, dynamic> json) {
    final m = json['metrics'] is Map
        ? Map<String, dynamic>.from(json['metrics'] as Map)
        : const <String, dynamic>{};
    int n(String k) => (m[k] is num) ? (m[k] as num).toInt() : 0;
    return SellerAnalyticsEntity(
      range: json['range']?.toString() ?? '30d',
      totalAds: n('totalAds'),
      activeAds: n('activeAds'),
      totalViews: n('totalViews'),
      totalFavorites: n('totalFavorites'),
      customerInquiries: n('customerInquiries'),
      conversationsCount: n('conversationsCount'),
      completedSellerReportedDeals: n('completedSellerReportedDeals'),
      responseRatePercent: n('responseRatePercent'),
      topPerformingAds: (json['topPerformingAds'] is List)
          ? (json['topPerformingAds'] as List)
              .whereType<Map>()
              .map((e) => SellerListingItemEntity.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      dailySeries: (json['dailySeries'] is List)
          ? (json['dailySeries'] as List)
              .whereType<Map>()
              .map((e) => SellerDailyPoint.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
    );
  }
}
