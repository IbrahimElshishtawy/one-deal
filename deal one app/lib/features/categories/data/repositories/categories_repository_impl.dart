import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/categories_repository.dart';
import '../dto/category_dto.dart';
import '../mappers/category_mapper.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final ApiClient apiClient;

  // In-memory cache for categories tree to prevent repeated network requests
  List<CategoryItem>? _cachedTree;
  DateTime? _treeCacheTime;
  static const Duration _cacheTtl = Duration(minutes: 30);

  CategoriesRepositoryImpl({required this.apiClient});

  @override
  Future<List<CategoryItem>> getCategoryTree() async {
    if (_cachedTree != null &&
        _treeCacheTime != null &&
        DateTime.now().difference(_treeCacheTime!) < _cacheTtl) {
      return _cachedTree!;
    }

    final response = await apiClient.get(ApiEndpoints.categories);
    final responseData = response.data;
    List<dynamic> items = [];

    if (responseData is Map && responseData['data'] is List) {
      items = responseData['data'] as List;
    } else if (responseData is List) {
      items = responseData;
    }

    final dtos = items
        .map((e) => CategoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    _cachedTree = dtos.map(CategoryMapper.toCategoryEntity).toList();
    _treeCacheTime = DateTime.now();

    return _cachedTree!;
  }

  @override
  Future<CategoryItem> getCategoryBySlug(String slug) async {
    final response = await apiClient.get(ApiEndpoints.categoryBySlug(slug));
    final responseData = response.data is Map
        ? (response.data['data'] as Map<String, dynamic>? ?? response.data)
        : <String, dynamic>{};

    final dto = CategoryDto.fromJson(Map<String, dynamic>.from(responseData as Map));
    return CategoryMapper.toCategoryEntity(dto);
  }

  @override
  Future<List<CategoryField>> getCategoryFields(String slug) async {
    final response = await apiClient.get(ApiEndpoints.categoryFields(slug));
    final responseData = response.data;
    List<dynamic> items = [];

    if (responseData is Map && responseData['data'] is List) {
      items = responseData['data'] as List;
    } else if (responseData is List) {
      items = responseData;
    }

    final dtos = items
        .map((e) => CategoryFieldDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return dtos.map(CategoryMapper.toFieldEntity).toList();
  }
}
