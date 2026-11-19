import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/data/repositories/search_repository_impl.dart';
import 'package:market_space/features/search/domain/entities/search_result.dart';
import 'package:market_space/features/search/domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchRepositoryImpl(apiClient: apiClient);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchActiveQueryDtoProvider = StateProvider<SearchQueryDto>((ref) {
  return const SearchQueryDto();
});

final searchResultsProvider = FutureProvider<SearchResult>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  final queryDto = ref.watch(searchActiveQueryDtoProvider);

  if (!queryDto.hasAnyFilter) {
    // Default browse: return latest products from backend when browsing without filters
    return repository.search(queryDto);
  }

  return repository.search(queryDto);
});
