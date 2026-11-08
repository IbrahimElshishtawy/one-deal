import '../../domain/entities/category_entity.dart';
import '../dto/category_dto.dart';

class CategoryMapper {
  static CategoryFieldType parseFieldType(String type) {
    switch (type.toLowerCase()) {
      case 'number':
        return CategoryFieldType.number;
      case 'select':
        return CategoryFieldType.select;
      case 'multi_select':
      case 'multiselect':
        return CategoryFieldType.multiSelect;
      case 'boolean':
        return CategoryFieldType.boolean;
      default:
        return CategoryFieldType.text;
    }
  }

  static CategoryField toFieldEntity(CategoryFieldDto dto) {
    List<String> options = [];
    if (dto.validationRules != null && dto.validationRules!['options'] is List) {
      options = (dto.validationRules!['options'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return CategoryField(
      fieldKey: dto.fieldKey,
      fieldType: parseFieldType(dto.fieldType),
      labelAr: dto.labelAr,
      labelEn: dto.labelEn,
      isRequired: dto.isRequired,
      isFilterable: dto.isFilterable,
      options: options,
      sortOrder: dto.sortOrder,
    );
  }

  static CategoryItem toCategoryEntity(CategoryDto dto) {
    return CategoryItem(
      id: dto.id,
      slug: dto.slug,
      nameAr: dto.nameAr,
      nameEn: dto.nameEn,
      iconName: dto.iconName,
      iconUrl: dto.iconUrl,
      parentId: dto.parentId,
      sortOrder: dto.sortOrder,
      subcategories: dto.children.map(toCategoryEntity).toList(),
      fields: dto.fields.map(toFieldEntity).toList(),
    );
  }
}
