import 'package:market_space/features/listings/data/mappers/listing_mapper.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/domain/entities/search_result.dart';

class SearchMapper {
  static SearchResult toEntity(SearchResponseDto dto) {
    return SearchResult(
      items: dto.items.map(ListingMapper.toItemEntity).toList(),
      totalCount: dto.meta.total,
      currentPage: dto.meta.page,
      totalPages: dto.meta.totalPages,
      query: dto.meta.query,
    );
  }
}
