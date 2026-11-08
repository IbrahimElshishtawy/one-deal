import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

class SearchResult {
  final List<ListingItem> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final String query;

  const SearchResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.query,
  });

  bool get hasMore => currentPage < totalPages;
}
