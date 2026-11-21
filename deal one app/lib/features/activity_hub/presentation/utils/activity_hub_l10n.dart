import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:market_space/app/app_localization.dart';
import 'package:market_space/features/activity_hub/domain/entities/activity_hub_tab.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';

/// Shared localization and formatting helpers for the Activity & Commerce Hub.
class ActivityHubL10n {
  static String formatPrice(
    double amount, {
    String currency = 'EGP',
    required bool isArabic,
  }) {
    final formatted = NumberFormat('#,##0.##').format(amount);
    if (currency.toUpperCase() == 'EGP') {
      return isArabic ? '$formatted ج.م' : '$formatted EGP';
    }
    return '$formatted $currency';
  }

  static String tabLabel(BuildContext context, ActivityHubTab tab) {
    final l10n = AppLocalization.of(context);
    switch (tab) {
      case ActivityHubTab.cart:
        return l10n.activityTabCart;
      case ActivityHubTab.bookings:
        return l10n.activityTabBookings;
      case ActivityHubTab.rfq:
        return l10n.activityTabRfq;
      case ActivityHubTab.favorites:
        return l10n.activityTabFavorites;
    }
  }

  static String sectorLabel(
    BuildContext context,
    MarketplaceSectorCategory sector,
  ) {
    final l10n = AppLocalization.of(context);
    switch (sector) {
      case MarketplaceSectorCategory.all:
        return l10n.activityFilterAll;
      case MarketplaceSectorCategory.realEstate:
        return l10n.favoritesSectorRealEstate;
      case MarketplaceSectorCategory.carsMaintenance:
        return l10n.favoritesSectorCars;
      case MarketplaceSectorCategory.servicesEngineering:
        return l10n.favoritesSectorServices;
      case MarketplaceSectorCategory.buildingMaterials:
        return l10n.favoritesSectorBuildingMaterials;
      case MarketplaceSectorCategory.homeAppliances:
        return l10n.favoritesSectorAppliances;
      case MarketplaceSectorCategory.fashionAccessories:
        return l10n.favoritesSectorFashion;
    }
  }

  static String bookingCategoryLabel(
    BuildContext context,
    BookingCategory category,
  ) {
    final l10n = AppLocalization.of(context);
    switch (category) {
      case BookingCategory.realEstate:
        return l10n.bookingsFilterRealEstate;
      case BookingCategory.carsMaintenance:
        return l10n.bookingsFilterCars;
      case BookingCategory.servicesEngineering:
        return l10n.bookingsFilterServices;
    }
  }

  static String bookingTypeLabel(BuildContext context, BookingType type) {
    final l10n = AppLocalization.of(context);
    switch (type) {
      case BookingType.propertyViewing:
        return l10n.bookingsTypePropertyViewing;
      case BookingType.propertyInspection:
        return l10n.bookingsTypePropertyInspection;
      case BookingType.agentContact:
        return l10n.bookingsTypeAgentContact;
      case BookingType.vehicleInspection:
        return l10n.bookingsTypeVehicleInspection;
      case BookingType.maintenanceBooking:
        return l10n.bookingsTypeMaintenance;
      case BookingType.serviceCenter:
        return l10n.bookingsTypeServiceCenter;
      case BookingType.plumbing:
        return l10n.bookingsTypePlumbing;
      case BookingType.electricity:
        return l10n.bookingsTypeElectricity;
      case BookingType.airConditioning:
        return l10n.bookingsTypeAc;
      case BookingType.construction:
        return l10n.bookingsTypeConstruction;
      case BookingType.engineering:
        return l10n.bookingsTypeEngineering;
    }
  }

  static String bookingStatusLabel(BuildContext context, BookingStatus status) {
    final l10n = AppLocalization.of(context);
    switch (status) {
      case BookingStatus.pending:
        return l10n.bookingsStatusPending;
      case BookingStatus.confirmed:
        return l10n.bookingsStatusConfirmed;
      case BookingStatus.rejected:
        return l10n.bookingsStatusRejected;
      case BookingStatus.cancelled:
        return l10n.bookingsStatusCancelled;
      case BookingStatus.completed:
        return l10n.bookingsStatusCompleted;
      case BookingStatus.unknown:
        return l10n.bookingsStatusUnknown;
    }
  }

  static String rfqStatusLabel(BuildContext context, RfqStatus status) {
    final l10n = AppLocalization.of(context);
    switch (status) {
      case RfqStatus.draft:
        return l10n.rfqStatusDraft;
      case RfqStatus.submitted:
        return l10n.rfqStatusSubmitted;
      case RfqStatus.underReview:
        return l10n.rfqStatusUnderReview;
      case RfqStatus.quoted:
        return l10n.rfqStatusQuoted;
      case RfqStatus.accepted:
        return l10n.rfqStatusAccepted;
      case RfqStatus.rejected:
        return l10n.rfqStatusRejected;
      case RfqStatus.closed:
        return l10n.rfqStatusClosed;
      case RfqStatus.unknown:
        return l10n.bookingsStatusUnknown;
    }
  }
}
