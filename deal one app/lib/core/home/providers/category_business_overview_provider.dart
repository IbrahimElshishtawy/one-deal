import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Immutable, user-scoped business overview snapshot for an activated
/// seller/provider/supplier inside a single category Home Page.
///
/// All numbers are computed strictly from real backend data:
/// - Listings lifecycle counts separate Moderation (`pending`), Publication
///   (`published`), and Availability (`available`).
/// - Views are nullable and omitted from UI unless real backend views exist.
/// - Provider bookings (`role=provider`) are strictly separated from buyer bookings.
/// - Supplier RFQs (`scope=open_for_suppliers`) are strictly separated from buyer RFQs.
@immutable
class CategoryBusinessOverview {
  final String categorySlug;
  final String accountName;
  final String accountType;

  /// For Cars & Maintenance: explicitly separates Car Sales from Maintenance Services.
  final bool showAutomotiveSales;
  final bool showAutomotiveMaintenance;

  // Orthogonal listing lifecycle counts
  final int totalListings;
  final int publishedListings;
  final int pendingModerationListings;
  final int availableListings;

  /// Null when backend does not report views > 0 for the account's listings.
  final int? totalViews;

  /// Unread/active buyer inquiries when the user's role permits `chat:respond`.
  final int? incomingInquiriesCount;

  // Services & Automotive Maintenance provider metrics (role=provider)
  final int incomingBookingsCount;
  final int upcomingAppointmentsCount;

  // Building Materials supplier metrics (scope=open_for_suppliers)
  final int incomingRfqsCount;
  final int submittedQuotationsCount;

  final bool isLoading;
  final String? error;
  final bool ownerEndpointGapActive;

  const CategoryBusinessOverview({
    required this.categorySlug,
    required this.accountName,
    required this.accountType,
    this.showAutomotiveSales = false,
    this.showAutomotiveMaintenance = false,
    this.totalListings = 0,
    this.publishedListings = 0,
    this.pendingModerationListings = 0,
    this.availableListings = 0,
    this.totalViews,
    this.incomingInquiriesCount,
    this.incomingBookingsCount = 0,
    this.upcomingAppointmentsCount = 0,
    this.incomingRfqsCount = 0,
    this.submittedQuotationsCount = 0,
    this.isLoading = false,
    this.error,
    this.ownerEndpointGapActive = false,
  });
}

/// Authoritative Role-Based Business Overview provider for a category Home Page.
///
/// Security & Zero-Flicker guarantees:
/// - Returns `null` when unauthenticated, while capabilities are loading, or
///   when the user lacks the verified capability for [categorySlug].
/// - Never triggers seller/provider API calls for buyers or guests.
/// - Isolates failures so a business overview error never breaks buyer content.
final categoryBusinessOverviewProvider =
    Provider.family<CategoryBusinessOverview?, String>((ref, categorySlug) {
      final normalized = MapCategoryRegistry.normalizeSlug(categorySlug);
      final capabilities = ref.watch(accountCapabilitiesProvider);

      // Zero-flicker & strict authorization gate:
      // Do not show any business section while loading or when unauthorized.
      if (!capabilities.isAuthenticated || capabilities.isLoading) {
        return null;
      }

      final activeAccount = capabilities.effectiveAccount;
      if (activeAccount == null ||
          !activeAccount.isActive ||
          !activeAccount.isVerified) {
        return null;
      }

      final bool isCars = normalized == MapCategoryRegistry.carsSlug;
      final bool showAutoSales =
          isCars && capabilities.canManageAutomotiveListings;
      final bool showAutoMaint =
          isCars && capabilities.canManageAutomotiveMaintenanceServices;

      final bool isAuthorized = isCars
          ? (showAutoSales || showAutoMaint)
          : capabilities.isActivatedSellerForSection(normalized);

      if (!isAuthorized) {
        return null;
      }

      final sellerState = ref.watch(
        sellerListingsControllerProvider(normalized),
      );
      final ownItems = sellerState.items;

      int publishedCount = 0;
      int pendingCount = 0;
      int availableCount = 0;
      int viewsSum = 0;

      for (final item in ownItems) {
        if (item.publicationStatus.toLowerCase() == 'published') {
          publishedCount++;
        }
        if (item.moderationStatus.toLowerCase() == 'pending') {
          pendingCount++;
        }
        if (item.availabilityStatus.toLowerCase() == 'available') {
          availableCount++;
        }
        viewsSum += item.viewsCount;
      }

      // Incoming inquiries (only when user role has `chat:respond`)
      int? inquiriesCount;
      if (capabilities.canRespondAsProvider) {
        final convsAsync = ref.watch(conversationsListProvider);
        inquiriesCount = convsAsync.whenOrNull(
          data: (list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount),
        );
      }

      // Services & Automotive Maintenance incoming bookings (provider-scoped only)
      int incomingBookings = 0;
      int upcomingAppointments = 0;
      bool extraLoading = false;
      if (normalized == MapCategoryRegistry.servicesSlug || showAutoMaint) {
        final bookingsAsync = ref.watch(
          providerIncomingBookingsProvider(normalized),
        );
        extraLoading = extraLoading || bookingsAsync.isLoading;
        final bookings = bookingsAsync.valueOrNull ?? const <BookingEntity>[];
        incomingBookings = bookings
            .where((b) => b.status == BookingStatus.pending)
            .length;
        upcomingAppointments = bookings
            .where((b) => b.status == BookingStatus.confirmed)
            .length;
      }

      // Building Materials supplier RFQs & Quotations (supplier-scoped only)
      int incomingRfqs = 0;
      int submittedQuotations = 0;
      if (normalized == MapCategoryRegistry.buildingMaterialsSlug) {
        final rfqsAsync = ref.watch(supplierOpenRfqsProvider(normalized));
        extraLoading = extraLoading || rfqsAsync.isLoading;
        final rfqs = rfqsAsync.valueOrNull ?? const [];
        incomingRfqs = rfqs.length;
        for (final rfq in rfqs) {
          submittedQuotations += rfq.quotations
              .where(
                (q) =>
                    q.supplierName.trim().toLowerCase() ==
                    activeAccount.displayName.trim().toLowerCase(),
              )
              .length;
        }
      }

      return CategoryBusinessOverview(
        categorySlug: normalized,
        accountName: activeAccount.displayName,
        accountType: activeAccount.accountType,
        showAutomotiveSales: showAutoSales,
        showAutomotiveMaintenance: showAutoMaint,
        totalListings: ownItems.length,
        publishedListings: publishedCount,
        pendingModerationListings: pendingCount,
        availableListings: availableCount,
        totalViews: viewsSum > 0 ? viewsSum : null,
        incomingInquiriesCount: inquiriesCount,
        incomingBookingsCount: incomingBookings,
        upcomingAppointmentsCount: upcomingAppointments,
        incomingRfqsCount: incomingRfqs,
        submittedQuotationsCount: submittedQuotations,
        isLoading: sellerState.isLoading || extraLoading,
        error: sellerState.error,
        ownerEndpointGapActive: sellerState.ownerEndpointGapActive,
      );
    });
