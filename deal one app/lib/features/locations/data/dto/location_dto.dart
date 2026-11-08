class CityDto {
  final int id;
  final int governorateId;
  final String nameAr;
  final String nameEn;
  final String slug;
  final bool isActive;

  const CityDto({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.isActive = true,
  });

  factory CityDto.fromJson(Map<String, dynamic> json) {
    return CityDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      governorateId: (json['governorateId'] ?? json['governorate_id'] as num?)?.toInt() ?? 0,
      nameAr: json['nameAr']?.toString() ?? json['name_ar']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? json['name_en']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isActive: json['isActive'] != false && json['is_active'] != false,
    );
  }
}

class GovernorateDto {
  final int id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final int sortOrder;
  final bool isActive;
  final List<CityDto> cities;

  const GovernorateDto({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.sortOrder = 0,
    this.isActive = true,
    this.cities = const [],
  });

  factory GovernorateDto.fromJson(Map<String, dynamic> json) {
    final citiesRaw = json['cities'] as List?;
    return GovernorateDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nameAr: json['nameAr']?.toString() ?? json['name_ar']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? json['name_en']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      sortOrder: (json['sortOrder'] ?? json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] != false && json['is_active'] != false,
      cities: citiesRaw != null
          ? citiesRaw
              .map((c) => CityDto.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList()
          : const [],
    );
  }
}

class AreaDto {
  final String id;
  final int cityId;
  final String nameAr;
  final String nameEn;
  final bool isActive;

  const AreaDto({
    required this.id,
    required this.cityId,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
  });

  factory AreaDto.fromJson(Map<String, dynamic> json) {
    return AreaDto(
      id: json['id']?.toString() ?? '',
      cityId: (json['cityId'] ?? json['city_id'] as num?)?.toInt() ?? 0,
      nameAr: json['nameAr']?.toString() ?? json['name_ar']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? json['name_en']?.toString() ?? '',
      isActive: json['isActive'] != false && json['is_active'] != false,
    );
  }
}
