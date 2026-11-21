# 04 — Localization

All user-facing strings in the Activity & Commerce Hub are localized in both English (`lib/l10n/app_en.arb`) and Arabic (`lib/l10n/app_ar.arb`) and generated via `flutter gen-l10n` into `lib/l10n/generated/app_localizations.dart` (accessed via `AppLocalization.of(context)`).

## Translation Groups Added
- **Hub & Navigation:** `activityHubTitle`, `activityHubSubtitle`, `activityTabCart`, `activityTabBookings`, `activityTabRfq`, `activityTabFavorites`, `activitySearchHint`, `activityFilterAll`, summary count keys.
- **Shopping Cart:** `cartTitle`, `cartEmptyTitle`, `cartEmptyMessage`, `cartSellerLabel`, `cartSizeLabel`, `cartColorLabel`, `cartRemoveItem`, `cartSaveForLater`, `cartSubtotalLabel`, `cartTotalLabel`, `cartCheckoutAction`, `cartV1CommerceNotice`, confirmation dialogs.
- **Bookings & Appointments:** `bookingsTitle`, `bookingsFilterRealEstate`, `bookingsFilterCars`, `bookingsFilterServices`, all 11 `bookingsType*` keys, all 6 `bookingsStatus*` keys, `bookingsReferenceLabel`, validation & backend notice keys.
- **RFQ:** `rfqTitle`, `rfqCreateAction`, `rfqCreateTitle`, form labels/hints/validation, all 7 `rfqStatus*` keys, `rfqReferenceLabel`, `rfqQuotationsCountLabel`, `rfqAcceptQuotationAction`, `rfqRejectQuotationAction`.
- **Favorites:** `favoritesTitle`, `favoritesEmptyTitle`, `favoritesSearchEmptyTitle`, all 6 `favoritesSector*` keys, `favoritesOpenListingAction`, `favoritesGoToSectionAction`.
- **Marketplace Actions:** `actionRequestViewing`, `actionBookInspection`, `actionBookService`, `actionRequestQuotation`, `actionContactSeller`.
