import '../entities/category_entity.dart';

abstract class CategoriesRepository {
  Future<List<CategoryItem>> getCategoryTree();
  Future<CategoryItem> getCategoryBySlug(String slug);
  Future<List<CategoryField>> getCategoryFields(String slug);
}
