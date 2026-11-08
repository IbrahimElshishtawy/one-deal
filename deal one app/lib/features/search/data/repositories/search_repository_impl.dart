import 'package:dio/dio.dart';
import 'package:market_space/core/network/api_client.dart';
import 'package:market_space/core/network/api_endpoints.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/data/mappers/search_mapper.dart';
import 'package:market_space/features/search/domain/entities/search_result.dart';
import 'package:market_space/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final ApiClient apiClient;
  CancelToken? _currentCancelToken;

  SearchRepositoryImpl({required this.apiClient});

  @override
  Future<SearchResult> search(SearchQueryDto query) async {
    // Automatically cancel pending flight for responsive typing/debouncing
    _currentCancelToken?.cancel('Superseded by new search request');
    _currentCancelToken = CancelToken();

    final response = await apiClient.get(
      ApiEndpoints.search,
      queryParameters: query.toQueryParams(),
      cancelToken: _currentCancelToken,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final dto = SearchResponseDto.fromJson(data);
      return SearchMapper.toEntity(dto);
    }

    return SearchResult(
      items: const [],
      totalCount: 0,
      currentPage: query.page,
      totalPages: 1,
      query: query.query,
    );
  }
}
