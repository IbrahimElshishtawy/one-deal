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

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  final cache = ref.watch(hybridCacheManagerProvider);
  return cache.getSearchHistory();
});

final searchResultsProvider = FutureProvider<SearchResult>((ref) async {
  final repository = ref.watch(searchRepositoryProvider);
  final queryDto = ref.watch(searchActiveQueryDtoProvider);
  final cache = ref.watch(hybridCacheManagerProvider);

  if (queryDto.query.trim().length >= 2) {
    await cache.addSearchHistory(queryDto.query.trim());
    ref.invalidate(searchHistoryProvider);
  }

  return repository.search(queryDto);
});
