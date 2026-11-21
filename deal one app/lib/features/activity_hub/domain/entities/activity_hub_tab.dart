import 'package:market_space/core/routing/route_names.dart';

/// Primary navigation tabs inside the Activity & Commerce Hub.
enum ActivityHubTab {
  cart,
  bookings,
  rfq,
  favorites;

  static ActivityHubTab fromQuery(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'cart':
        return ActivityHubTab.cart;
      case 'bookings':
        return ActivityHubTab.bookings;
      case 'rfq':
        return ActivityHubTab.rfq;
      case 'favorites':
        return ActivityHubTab.favorites;
      default:
        return ActivityHubTab.cart;
    }
  }
}

/// Canonical 6 marketplace sectors used across Favorites, Cart, Bookings, and RFQ.
enum MarketplaceSectorCategory {
  all,
  realEstate,
  carsMaintenance,
  servicesEngineering,
  buildingMaterials,
  homeAppliances,
  fashionAccessories;

  /// Resolves a backend category slug into a canonical [MarketplaceSectorCategory].
  static MarketplaceSectorCategory fromCategorySlug(String? slug) {
    final s = (slug ?? '').toLowerCase().trim();
    if (s.contains('real') ||
        s.contains('estate') ||
        s.contains('property') ||
        s.contains('land') ||
        s.contains('apartment') ||
        s.contains('villa') ||
        s.contains('عقار')) {
      return MarketplaceSectorCategory.realEstate;
    }
    if (s.contains('car') ||
        s.contains('auto') ||
        s.contains('vehicle') ||
        s.contains('motor') ||
        s.contains('سيار')) {
      return MarketplaceSectorCategory.carsMaintenance;
    }
    if (s.contains('service') ||
        s.contains('engineer') ||
        s.contains('plumb') ||
        s.contains('ac') ||
        s.contains('maint') ||
        s.contains('خدم')) {
      return MarketplaceSectorCategory.servicesEngineering;
    }
    if (s.contains('build') ||
        s.contains('construct') ||
        s.contains('material') ||
        s.contains('electr') ||
        s.contains('cement') ||
        s.contains('steel') ||
        s.contains('بناء')) {
      return MarketplaceSectorCategory.buildingMaterials;
    }
    if (s.contains('appliance') ||
        s.contains('decor') ||
        s.contains('furniture') ||
        s.contains('home') ||
        s.contains('أجهز')) {
      return MarketplaceSectorCategory.homeAppliances;
    }
    if (s.contains('fashion') ||
        s.contains('cloth') ||
        s.contains('accessor') ||
        s.contains('shoe') ||
        s.contains('أزياء')) {
      return MarketplaceSectorCategory.fashionAccessories;
    }
    return MarketplaceSectorCategory.all;
  }

  /// Target route for navigating to the original marketplace section.
  String get sectionRoute {
    switch (this) {
      case MarketplaceSectorCategory.all:
        return RouteNames.root;
      case MarketplaceSectorCategory.realEstate:
        return RouteNames.realEstate;
      case MarketplaceSectorCategory.carsMaintenance:
        return RouteNames.cars;
      case MarketplaceSectorCategory.servicesEngineering:
        return RouteNames.homeServices;
      case MarketplaceSectorCategory.buildingMaterials:
        return RouteNames.buildingMaterials;
      case MarketplaceSectorCategory.homeAppliances:
        return RouteNames.homeAppliances;
      case MarketplaceSectorCategory.fashionAccessories:
        return RouteNames.fashion;
    }
  }
}
