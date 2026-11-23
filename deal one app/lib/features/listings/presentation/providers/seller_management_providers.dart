import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/data/repositories/bookings_repository_impl.dart';
import 'package:market_space/features/activity_hub/data/repositories/rfq_repository_impl.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

class SellerListingsState {
  final List<ListingItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMutating;
  final bool hasMore;
  final String? nextCursor;
  final String? error;
  final String? selectedModerationFilter;
  final String? selectedPublicationFilter;
  final String? selectedAvailabilityFilter;

  /// Indicates whether the current backend lacks a dedicated owner-scoped
  /// `GET /api/v1/listings/my` endpoint for non-published statuses
  /// (Draft, Pending, Rejected, Hidden, Expired, Archived).
  final bool ownerEndpointGapActive;

  const SellerListingsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
    this.selectedModerationFilter,
    this.selectedPublicationFilter,
    this.selectedAvailabilityFilter,
    this.ownerEndpointGapActive = true,
  });

  SellerListingsState copyWith({
    List<ListingItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMutating,
    bool? hasMore,
    String? nextCursor,
    bool clearCursor = false,
    String? error,
    bool clearError = false,
    String? selectedModerationFilter,
    bool clearModerationFilter = false,
    String? selectedPublicationFilter,
    bool clearPublicationFilter = false,
    String? selectedAvailabilityFilter,
    bool clearAvailabilityFilter = false,
    bool? ownerEndpointGapActive,
  }) {
    return SellerListingsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      error: clearError ? null : (error ?? this.error),
      selectedModerationFilter: clearModerationFilter
          ? null
          : (selectedModerationFilter ?? this.selectedModerationFilter),
      selectedPublicationFilter: clearPublicationFilter
          ? null
          : (selectedPublicationFilter ?? this.selectedPublicationFilter),
      selectedAvailabilityFilter: clearAvailabilityFilter
          ? null
          : (selectedAvailabilityFilter ?? this.selectedAvailabilityFilter),
      ownerEndpointGapActive:
          ownerEndpointGapActive ?? this.ownerEndpointGapActive,
    );
  }

  List<ListingItem> get filteredItems {
    return items.where((item) {
      if (selectedModerationFilter != null &&
          item.moderationStatus.toLowerCase() !=
              selectedModerationFilter!.toLowerCase()) {
        return false;
      }
      if (selectedPublicationFilter != null &&
          item.publicationStatus.toLowerCase() !=
              selectedPublicationFilter!.toLowerCase()) {
        return false;
      }
      if (selectedAvailabilityFilter != null &&
          item.availabilityStatus.toLowerCase() !=
              selectedAvailabilityFilter!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }
}

class SellerListingsController extends StateNotifier<SellerListingsState> {
  final Ref _ref;
  final String categorySlug;

  SellerListingsController(this._ref, this.categorySlug)
      : super(const SellerListingsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final capabilities = _ref.read(accountCapabilitiesProvider);
    final activeAccount = capabilities.effectiveAccount;
    if (!capabilities.isActivatedSellerForSection(categorySlug) ||
        activeAccount == null) {
      state = const SellerListingsState(
        items: [],
        isLoading: false,
        hasMore: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearCursor: true);
    try {
      final repo = _ref.read(listingsRepositoryProvider);
      final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
      final feed = await repo.getListingsFeed(
        FilterListingsDto(
          categorySlug: normalized,
          limit: 20,
        ),
      );

      // Strictly filter to listings belonging to the active verified account.
      final ownItems = _filterOwnAccountItems(feed.items, activeAccount.id, activeAccount.displayName);

      state = state.copyWith(
        items: ownItems,
        isLoading: false,
        hasMore: feed.hasMore,
        nextCursor: feed.nextCursor,
        ownerEndpointGapActive: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }
    final capabilities = _ref.read(accountCapabilitiesProvider);
    final activeAccount = capabilities.effectiveAccount;
    if (!capabilities.isActivatedSellerForSection(categorySlug) ||
        activeAccount == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _ref.read(listingsRepositoryProvider);
      final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
      final feed = await repo.getListingsFeed(
        FilterListingsDto(
          categorySlug: normalized,
          cursor: state.nextCursor,
          limit: 20,
        ),
      );

      final ownMore = _filterOwnAccountItems(feed.items, activeAccount.id, activeAccount.displayName);
      final existingIds = state.items.map((e) => e.id).toSet();
      final merged = [
        ...state.items,
        ...ownMore.where((e) => !existingIds.contains(e.id)),
      ];

      state = state.copyWith(
        items: merged,
        isLoadingMore: false,
        hasMore: feed.hasMore,
        nextCursor: feed.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  List<ListingItem> _filterOwnAccountItems(
    List<ListingItem> items,
    String accountId,
    String displayName,
  ) {
    return items.where((item) {
      if (item.accountId != null && item.accountId!.isNotEmpty) {
        return item.accountId == accountId;
      }
      return displayName.isNotEmpty &&
          item.sellerName.trim().toLowerCase() ==
              displayName.trim().toLowerCase();
    }).toList();
  }

  void setModerationFilter(String? value) {
    state = value == null
        ? state.copyWith(clearModerationFilter: true)
        : state.copyWith(selectedModerationFilter: value);
  }

  void setPublicationFilter(String? value) {
    state = value == null
        ? state.copyWith(clearPublicationFilter: true)
        : state.copyWith(selectedPublicationFilter: value);
  }

  void setAvailabilityFilter(String? value) {
    state = value == null
        ? state.copyWith(clearAvailabilityFilter: true)
        : state.copyWith(selectedAvailabilityFilter: value);
  }

  Future<bool> updatePublicationStatus(String listingId, String status) async {
    final capabilities = _ref.read(accountCapabilitiesProvider);
    if (!capabilities.isActivatedSellerForSection(categorySlug)) return false;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ref
          .read(listingsRepositoryProvider)
          .updateListingPublicationStatus(listingId, status);
      await loadInitial();
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateAvailability(String listingId, String availability) async {
    final capabilities = _ref.read(accountCapabilitiesProvider);
    if (!capabilities.isActivatedSellerForSection(categorySlug)) return false;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ref
          .read(listingsRepositoryProvider)
          .updateListingAvailability(listingId, availability);
      await loadInitial();
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteListing(String listingId) async {
    final capabilities = _ref.read(accountCapabilitiesProvider);
    if (!capabilities.isActivatedSellerForSection(categorySlug)) return false;

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _ref.read(listingsRepositoryProvider).deleteListing(listingId);
      state = state.copyWith(
        items: state.items.where((i) => i.id != listingId).toList(),
        isMutating: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      return false;
    }
  }
}

final sellerListingsControllerProvider = StateNotifierProvider.family<
    SellerListingsController, SellerListingsState, String>((ref, slug) {
  return SellerListingsController(ref, slug);
});

/// Provider-side incoming booking requests (`GET /api/v1/bookings?role=provider&categorySlug=...`).
/// Strictly separated from buyer's own bookings (`role=requester`).
final providerIncomingBookingsProvider =
    FutureProvider.family<List<BookingEntity>, String>((ref, categorySlug) async {
  final session = ref.watch(sessionProvider);
  final capabilities = ref.watch(accountCapabilitiesProvider);
  if (!session.isAuthenticated ||
      !capabilities.isActivatedSellerForSection(categorySlug)) {
    return const [];
  }
  final repo = ref.watch(bookingsRepositoryProvider);
  if (repo is BookingsRepositoryImpl && repo.isBackendSupported) {
    return repo.getBookings(
      role: 'provider',
      categorySlug: MapCategoryRegistry.normalizeSlug(categorySlug),
    );
  }
  return const [];
});

/// Supplier-side open buyer RFQs (`GET /api/v1/rfqs?scope=open_for_suppliers&categorySlug=building-materials`).
/// Strictly separated from buyer's own RFQs (`scope=mine`).
final supplierOpenRfqsProvider =
    FutureProvider.family<List<RfqRequestEntity>, String>((ref, categorySlug) async {
  final session = ref.watch(sessionProvider);
  final capabilities = ref.watch(accountCapabilitiesProvider);
  if (!session.isAuthenticated ||
      !capabilities.isActivatedSellerForSection(categorySlug)) {
    return const [];
  }
  final repo = ref.watch(rfqRepositoryProvider);
  if (repo is RfqRepositoryImpl && repo.isBackendSupported) {
    return repo.getMyRfqs(
      scope: 'open_for_suppliers',
      categorySlug: MapCategoryRegistry.normalizeSlug(categorySlug),
    );
  }
  return const [];
});
