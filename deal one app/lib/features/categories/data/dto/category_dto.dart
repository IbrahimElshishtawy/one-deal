class CategoryFieldDto {
  final String fieldKey;
  final String fieldType;
  final String labelAr;
  final String labelEn;
  final bool isRequired;
  final bool isFilterable;
  final Map<String, dynamic>? validationRules;
  final int sortOrder;

  const CategoryFieldDto({
    required this.fieldKey,
    required this.fieldType,
    required this.labelAr,
    required this.labelEn,
    this.isRequired = false,
    this.isFilterable = true,
    this.validationRules,
    this.sortOrder = 0,
  });

  factory CategoryFieldDto.fromJson(Map<String, dynamic> json) {
    return CategoryFieldDto(
      fieldKey: json['fieldKey']?.toString() ?? json['field_key']?.toString() ?? '',
      fieldType: json['fieldType']?.toString() ?? json['field_type']?.toString() ?? 'text',
      labelAr: json['labelAr']?.toString() ?? json['label_ar']?.toString() ?? '',
      labelEn: json['labelEn']?.toString() ?? json['label_en']?.toString() ?? '',
      isRequired: json['isRequired'] == true || json['is_required'] == true,
      isFilterable: json['isFilterable'] != false && json['is_filterable'] != false,
      validationRules: json['validationRules'] is Map
          ? (json['validationRules'] as Map).cast<String, dynamic>()
          : null,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
    );
  }
}

class CategoryDto {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? iconName;
  final String? iconUrl;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final List<CategoryDto> children;
  final List<CategoryFieldDto> fields;

  const CategoryDto({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.iconName,
    this.iconUrl,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
    this.fields = const [],
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final childrenRaw = json['children'] as List?;
    final fieldsRaw = json['fields'] as List?;

    return CategoryDto(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? json['name_ar']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? json['name_en']?.toString() ?? '',
      iconName: json['iconName']?.toString() ?? json['icon_name']?.toString(),
      iconUrl: json['iconUrl']?.toString() ?? json['icon_url']?.toString(),
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString(),
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
      isActive: json['isActive'] != false && json['is_active'] != false,
      children: childrenRaw != null
          ? childrenRaw
              .map((c) => CategoryDto.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList()
          : const [],
      fields: fieldsRaw != null
          ? fieldsRaw
              .map((f) => CategoryFieldDto.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList()
          : const [],
    );
  }
}
