import 'package:market_space/features/locations/data/dto/location_dto.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';

class LocationMapper {
  static CityEntity toCityEntity(CityDto dto) {
    return CityEntity(
      id: dto.id,
      governorateId: dto.governorateId,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      slug: dto.slug,
      isActive: dto.isActive,
    );
  }

  static GovernorateEntity toGovernorateEntity(GovernorateDto dto) {
    return GovernorateEntity(
      id: dto.id,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      slug: dto.slug,
      sortOrder: dto.sortOrder,
      isActive: dto.isActive,
      cities: dto.cities.map(toCityEntity).toList(),
    );
  }

  static AreaEntity toAreaEntity(AreaDto dto) {
    return AreaEntity(
      id: dto.id,
      cityId: dto.cityId,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      isActive: dto.isActive,
    );
  }
}
