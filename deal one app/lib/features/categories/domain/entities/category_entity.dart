enum CategoryFieldType { text, number, select, multiSelect, boolean }

class CategoryField {
  final String fieldKey;
  final CategoryFieldType fieldType;
  final String labelAr;
  final String labelEn;
  final bool isRequired;
  final bool isFilterable;
  final List<String> options;
  final int sortOrder;

  const CategoryField({
    required this.fieldKey,
    required this.fieldType,
    required this.labelAr,
    required this.labelEn,
    required this.isRequired,
    required this.isFilterable,
    this.options = const [],
    this.sortOrder = 0,
  });
}

class CategoryItem {
  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String? iconName;
  final String? iconUrl;
  final String? parentId;
  final int sortOrder;
  final List<CategoryItem> subcategories;
  final List<CategoryField> fields;

  const CategoryItem({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    this.iconName,
    this.iconUrl,
    this.parentId,
    this.sortOrder = 0,
    this.subcategories = const [],
    this.fields = const [],
  });

  bool get isRoot => parentId == null || parentId!.isEmpty;
}
