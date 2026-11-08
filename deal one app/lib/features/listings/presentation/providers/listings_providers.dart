import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/data/repositories/listings_repository_impl.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/domain/repositories/listings_repository.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ListingsRepositoryImpl(apiClient: apiClient);
});

final currentFeedFilterProvider = StateProvider<FilterListingsDto>((ref) {
  return const FilterListingsDto();
});

final listingsFeedProvider = FutureProvider<ListingFeed>((ref) async {
  final repository = ref.watch(listingsRepositoryProvider);
  final filter = ref.watch(currentFeedFilterProvider);
  return repository.getListingsFeed(filter);
});

final listingDetailsFamily = FutureProvider.family<ListingItem, String>((ref, id) async {
  final repository = ref.watch(listingsRepositoryProvider);
  return repository.getListingDetails(id);
});

class ContactRevealNotifier extends StateNotifier<AsyncValue<ContactRevealResult?>> {
  final ListingsRepository _repository;

  ContactRevealNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> reveal(String listingId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.revealContact(listingId);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final contactRevealProvider =
    StateNotifierProvider.family<ContactRevealNotifier, AsyncValue<ContactRevealResult?>, String>(
        (ref, listingId) {
  final repository = ref.watch(listingsRepositoryProvider);
  return ContactRevealNotifier(repository);
});
