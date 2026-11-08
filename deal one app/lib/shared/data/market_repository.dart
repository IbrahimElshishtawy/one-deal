import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../models/home_feed_models.dart';

abstract class MarketRepository {
  Future<List<RealEstateItem>> getRealEstateListings();
  Future<List<BuildingMaterialItem>> getBuildingMaterials();
  Future<List<ServiceProviderItem>> getServiceProviders();
  Future<List<InvestmentProjectItem>> getInvestmentProjects();
}

class MarketRepositoryImpl implements MarketRepository {
  final ApiClient? apiClient;

  MarketRepositoryImpl({this.apiClient});

  @override
  Future<List<RealEstateItem>> getRealEstateListings() async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.get(
          '/listings',
          queryParameters: {'categorySlug': 'real-estate', 'limit': 10},
        );
        final dynamic resData = res.data;
        List<dynamic> items = [];
        if (resData is Map && resData['data'] is List) {
          items = resData['data'] as List;
        } else if (resData is List) {
          items = resData;
        }

        if (items.isNotEmpty) {
          final fmt = NumberFormat.decimalPattern();
          return items.map<RealEstateItem>((item) {
            final data = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            final num priceNum = data['price'] is num
                ? data['price']
                : (num.tryParse(data['price']?.toString() ?? '0') ?? 0);
            final isRent = data['listingKind'] == 'rent';
            final attrs = data['attributes'] is Map
                ? Map<String, dynamic>.from(data['attributes'])
                : {};

            final mediaList = data['media'] as List?;
            final imageUrl =
                data['primaryImageUrl']?.toString() ??
                data['imageUrl']?.toString() ??
                (mediaList != null && mediaList.isNotEmpty
                    ? mediaList[0]['publicUrl']?.toString()
                    : null) ??
                'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80';

            return RealEstateItem(
              id: data['id']?.toString() ?? '',
              title: data['title']?.toString() ?? 'عقار مميز',
              price: '${fmt.format(priceNum)} ج.م',
              priceSuffix: isRent ? 'شهرياً' : 'كاش / تقسيط',
              type: isRent ? 'للإيجار' : 'للبيع',
              isVerified: true,
              badge: 'موثق رسمياً',
              beds: (attrs['rooms'] as num?)?.toInt() ?? 3,
              baths: (attrs['baths'] as num?)?.toInt() ?? 2,
              areaM2: (attrs['area_sqm'] as num?)?.toDouble() ?? 150.0,
              location:
                  data['location']?.toString() ??
                  data['areaName']?.toString() ??
                  'القاهرة الجديدة',
              timeAgo: 'اليوم',
              imageUrl: imageUrl,
            );
          }).toList();
        }
      } catch (_) {
        // Fall back to baseline
      }
    }

    // Baseline Egyptian Marketplace Real Estate
    return const [
      RealEstateItem(
        id: 're-eg-1',
        title: 'شقة فاخرة 185م تشطيب ألترا لوكس بحري بالنرجس التجمع الخامس',
        price: '4,350,000 ج.م',
        priceSuffix: 'كاش / تمويل',
        type: 'للبيع',
        isVerified: true,
        badge: 'توثيق رسمي',
        beds: 3,
        baths: 3,
        areaM2: 185,
        location: 'التجمع الخامس، القاهرة الجديدة',
        timeAgo: 'منذ ساعتين',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      ),
      RealEstateItem(
        id: 're-eg-2',
        title: 'شقة مفروشة 160م للإيجار بالتجمع كمبوند البنفسج أجهزة جديدة',
        price: '26,000 ج.م',
        priceSuffix: 'شهرياً',
        type: 'للإيجار',
        isVerified: true,
        badge: 'مفروشة بالكامل',
        beds: 3,
        baths: 2,
        areaM2: 160,
        location: 'التجمع الأول، القاهرة الجديدة',
        timeAgo: 'منذ 3 ساعات',
        imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
      ),
      RealEstateItem(
        id: 're-eg-3',
        title: 'تاون هاوس كورنر 280م للبيع بسوديك بيفرلي هيلز الشيخ زايد',
        price: '12,800,000 ج.م',
        priceSuffix: 'كاش',
        type: 'للبيع',
        isVerified: true,
        badge: 'استلام فوري',
        beds: 4,
        baths: 4,
        areaM2: 280,
        location: 'بيفرلي هيلز، الشيخ زايد',
        timeAgo: 'منذ 5 ساعات',
        imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }

  @override
  Future<List<BuildingMaterialItem>> getBuildingMaterials() async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.get(
          '/listings',
          queryParameters: {'categorySlug': 'building-materials', 'limit': 10},
        );
        final dynamic resData = res.data;
        List<dynamic> items = [];
        if (resData is Map && resData['data'] is List) {
          items = resData['data'] as List;
        } else if (resData is List) {
          items = resData;
        }

        if (items.isNotEmpty) {
          final fmt = NumberFormat.decimalPattern();
          return items.map<BuildingMaterialItem>((item) {
            final data = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            final num priceNum = data['price'] is num
                ? data['price']
                : (num.tryParse(data['price']?.toString() ?? '0') ?? 0);
            final attrs = data['attributes'] is Map
                ? Map<String, dynamic>.from(data['attributes'])
                : {};

            final mediaList = data['media'] as List?;
            final imageUrl =
                data['primaryImageUrl']?.toString() ??
                data['imageUrl']?.toString() ??
                (mediaList != null && mediaList.isNotEmpty
                    ? mediaList[0]['publicUrl']?.toString()
                    : null) ??
                'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?auto=format&fit=crop&w=800&q=80';

            return BuildingMaterialItem(
              id: data['id']?.toString() ?? '',
              title: data['title']?.toString() ?? 'مواد بناء وتوريدات',
              subtitle:
                  data['description']?.toString() ??
                  'توريد مباشر لجميع مواقع العمل والمشروعات',
              price: '${fmt.format(priceNum)} ج.م',
              unit: attrs['unit']?.toString() ?? 'للطن',
              tag: 'توريد معتمد',
              footerText: data['sellerName']?.toString() ?? 'مورد معتمد',
              hasCall: true,
              hasChat: true,
              imageUrl: imageUrl,
            );
          }).toList();
        }
      } catch (_) {
        // Fall back to baseline
      }
    }

    return const [
      BuildingMaterialItem(
        id: 'bm-eg-1',
        title: 'حديد تسليح عز أصلي مشرشر جميع الأقطار توريد فوري',
        subtitle: 'متوفر أقطار 10مم و 12مم و 16مم مع شهادة الجودة وبوالص الشحن',
        price: '38,500 ج.م',
        unit: 'للطن',
        tag: 'توريد طن',
        footerText: 'توصيل لجميع المواقع',
        hasCall: true,
        hasChat: true,
        imageUrl: 'https://images.unsplash.com/photo-1504917599217-d4dc5ebe6122?auto=format&fit=crop&w=800&q=80',
      ),
      BuildingMaterialItem(
        id: 'bm-eg-2',
        title: 'أسمنت السويدي بورتلاندي عادي رتبة 42.5N للخرسانات المسلحة',
        subtitle: 'شكاير 50 كجم محكمة الغلق وتوريد تريلات وجامبو',
        price: '2,450 ج.م',
        unit: 'للطن',
        tag: 'خرسانات ومسلح',
        footerText: 'مورد معتمد',
        hasCall: true,
        hasChat: true,
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=800&q=80',
      ),
      BuildingMaterialItem(
        id: 'bm-eg-3',
        title: 'كابلات وأسلاك السويدي إلكتريك نحاس أصلي معتمد كود QR',
        subtitle: 'لفات أصلية نحاس أحمر نقي 100% لتأسيس الشقق والمصانع',
        price: '1,850 ج.م',
        unit: 'لفة 100م',
        tag: 'تأسيس وضمان',
        footerText: 'موزع معتمد',
        hasCall: true,
        hasChat: false,
        imageUrl: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }

  @override
  Future<List<ServiceProviderItem>> getServiceProviders() async {
    if (apiClient != null) {
      try {
        final res = await apiClient!.get(
          '/listings',
          queryParameters: {'categorySlug': 'services', 'limit': 10},
        );
        final dynamic resData = res.data;
        List<dynamic> items = [];
        if (resData is Map && resData['data'] is List) {
          items = resData['data'] as List;
        } else if (resData is List) {
          items = resData;
        }

        if (items.isNotEmpty) {
          return items.map<ServiceProviderItem>((item) {
            final data = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item);
            final account = data['account'] is Map
                ? data['account'] as Map
                : {};

            return ServiceProviderItem(
              id: data['id']?.toString() ?? '',
              name:
                  account['displayName']?.toString() ??
                  data['sellerName']?.toString() ??
                  data['title']?.toString() ??
                  'مقدم خدمة معتمد',
              serviceDesc:
                  data['description']?.toString() ??
                  data['title']?.toString() ??
                  'خدمات منزلية وهندسية متكاملة',
              rating: 4.9,
              reviewsCount: 142,
              perkText: 'معاينة وضمان',
              actionLabel: 'طلب الخدمة',
              isVerified: true,
              categoryKey: data['category']?['slug']?.toString() ?? 'services',
            );
          }).toList();
        }
      } catch (_) {
        // Fall back to baseline
      }
    }

    return const [
      ServiceProviderItem(
        id: 'sp-eg-1',
        name: 'الشركة الهندسية للتشطيبات والديكور الحديث',
        serviceDesc: 'تشطيب شقق وفلل على المفتاح • دهانات جوتن وديكورات 3D',
        rating: 4.9,
        reviewsCount: 184,
        perkText: 'معاينة وتصميم 3D',
        actionLabel: 'طلب مقايسة',
        isVerified: true,
        categoryKey: 'finishing',
      ),
      ServiceProviderItem(
        id: 'sp-eg-2',
        name: 'الأمان لنقل ورفع العفش بالونش الهيدروليكي',
        serviceDesc: 'أوناش هيدروليكية للأدوار العليا وسيارات مقفلة مجهزة',
        rating: 5.0,
        reviewsCount: 215,
        perkText: 'تغليف آمن وضمان كامل',
        actionLabel: 'حجز ونش',
        isVerified: true,
        categoryKey: 'moving',
      ),
      ServiceProviderItem(
        id: 'sp-eg-3',
        name: 'المركز الفني لصيانة وغسيل التكييفات وشحن الفريون',
        serviceDesc: 'غسيل بالضغط العالي وشحن فريون أصلي وصيانة دورية للمنازل',
        rating: 4.8,
        reviewsCount: 96,
        perkText: 'استجابة سريعة في نفس اليوم',
        actionLabel: 'طلب صيانة',
        isVerified: true,
        categoryKey: 'ac',
      ),
    ];
  }

  @override
  Future<List<InvestmentProjectItem>> getInvestmentProjects() async {
    return const [
      InvestmentProjectItem(
        id: 'inv-eg-1',
        title: 'مشروع أبراج العاصمة الإدارية السكني التجاري',
        location: 'العاصمة الإدارية الجديدة، منطقة الأعمال المركزية',
        minInvestment: '250,000 ج.م',
        expectedReturn: 'عائد استثماري سنوي 15%',
        progressPercent: 0.85,
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      ),
      InvestmentProjectItem(
        id: 'inv-eg-2',
        title: 'مول تجاري إداري التجمع الخامس شارع التسعين',
        location: 'القاهرة الجديدة، التجمع الخامس',
        minInvestment: '500,000 ج.م',
        expectedReturn: 'عائد إيجاري مستهدف 18%',
        progressPercent: 0.70,
        imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }
}
