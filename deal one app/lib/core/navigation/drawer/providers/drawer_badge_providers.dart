import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';
import 'package:market_space/features/notifications/presentation/providers/user_notifications_providers.dart';

/// Live unread notifications count for the Drawer's Notifications item.
final drawerNotificationsUnreadProvider = Provider<int>((ref) {
  try {
    return ref.watch(userNotificationsProvider.select((s) => s.unreadCount));
  } catch (_) {
    return 0;
  }
});

/// Live unread chat messages count for the Drawer's Messages item.
final drawerChatUnreadProvider = Provider<int>((ref) {
  try {
    return ref.watch(unreadChatCountProvider);
  } catch (_) {
    return 0;
  }
});

/// Live incoming booking requests count for Services & Engineering providers.
final drawerIncomingServiceRequestsCountProvider = Provider<int>((ref) {
  try {
    return ref
            .watch(
              providerIncomingBookingsProvider(
                MapCategoryRegistry.servicesSlug,
              ),
            )
            .valueOrNull
            ?.length ??
        0;
  } catch (_) {
    return 0;
  }
});

/// Live incoming maintenance requests count for Automotive Maintenance providers.
final drawerIncomingMaintenanceRequestsCountProvider = Provider<int>((ref) {
  try {
    return ref
            .watch(
              providerIncomingBookingsProvider(
                MapCategoryRegistry.carsSlug,
              ),
            )
            .valueOrNull
            ?.length ??
        0;
  } catch (_) {
    return 0;
  }
});

/// Live incoming open buyer RFQs count for Building Materials suppliers.
final drawerIncomingRfqsCountProvider = Provider<int>((ref) {
  try {
    return ref
            .watch(
              supplierOpenRfqsProvider(
                MapCategoryRegistry.buildingMaterialsSlug,
              ),
            )
            .valueOrNull
            ?.length ??
        0;
  } catch (_) {
    return 0;
  }
});

/// Key-based fallback resolver preserved for backward compatibility.
final drawerBadgeCountProvider =
    Provider.family<int, String?>((ref, badgeKey) {
  if (badgeKey == null || badgeKey.isEmpty) return 0;
  switch (badgeKey) {
    case 'chat_unread':
      return ref.watch(drawerChatUnreadProvider);
    case 'notifications_unread':
      return ref.watch(drawerNotificationsUnreadProvider);
    case 'incoming_bookings_services':
      return ref.watch(drawerIncomingServiceRequestsCountProvider);
    case 'incoming_bookings_cars':
      return ref.watch(drawerIncomingMaintenanceRequestsCountProvider);
    case 'incoming_rfqs_building_materials':
      return ref.watch(drawerIncomingRfqsCountProvider);
    default:
      return 0;
  }
});
