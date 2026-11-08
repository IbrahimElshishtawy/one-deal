import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/domain/entities/search_result.dart';

abstract class SearchRepository {
  Future<SearchResult> search(SearchQueryDto query);
}
