class CityEntity {
  final int id;
  final int governorateId;
  final String nameAr;
  final String nameEn;
  final String slug;
  final bool isActive;

  const CityEntity({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.isActive = true,
  });

  String localizedName(String langCode) => langCode == 'ar' ? nameAr : (nameEn.isNotEmpty ? nameEn : nameAr);
}

class GovernorateEntity {
  final int id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final int sortOrder;
  final bool isActive;
  final List<CityEntity> cities;

  const GovernorateEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    this.sortOrder = 0,
    this.isActive = true,
    this.cities = const [],
  });

  String localizedName(String langCode) => langCode == 'ar' ? nameAr : (nameEn.isNotEmpty ? nameEn : nameAr);
}

class AreaEntity {
  final String id;
  final int cityId;
  final String nameAr;
  final String nameEn;
  final bool isActive;

  const AreaEntity({
    required this.id,
    required this.cityId,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
  });

  String localizedName(String langCode) => langCode == 'ar' ? nameAr : (nameEn.isNotEmpty ? nameEn : nameAr);
}
