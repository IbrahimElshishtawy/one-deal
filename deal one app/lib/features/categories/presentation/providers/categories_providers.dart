import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/categories_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoriesRepositoryImpl(apiClient: apiClient);
});

final categoryTreeProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getCategoryTree();
});

final categoryBySlugProvider =
    FutureProvider.family<CategoryItem, String>((ref, slug) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getCategoryBySlug(slug);
});

final categoryFieldsProvider =
    FutureProvider.family<List<CategoryField>, String>((ref, slug) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getCategoryFields(slug);
});
