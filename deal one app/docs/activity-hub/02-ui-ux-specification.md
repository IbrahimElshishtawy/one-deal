# 02 — UI/UX Specification

## 1. Design System Alignment
All components use Deal One's centralized design tokens:
- **Colors:** `AppColors` (`backgroundOf`, `surfaceOf`, `surfaceSecondaryOf`, `textPrimaryOf`, `textSecondaryOf`, `textMutedOf`, `borderOf`, `errorOf`, `successOf`, `warningOf`, `infoOf`) and `DealOneDesignColors` (`navy` `#1B2B48`, `amberPrice` `#D97706`).
- **Spacing & Radii:** `AppSpacing` (`xs`, `sm`, `md`, `lg`, `xl`, `xxl`) and `AppRadii` (`sm`, `md`, `lg`, `full`).
- **Responsiveness:** `ResponsiveContext` (`horizontalScreenPadding`, `isSmallPhone`, `isTablet`).

## 2. Hub Layout Structure
1. **Header (`ActivityHubHeader`)**: Back button, localized title & subtitle, and contextual Clear Cart button when Cart has items.
2. **Summary Bar (`ActivitySummarySection`)**: Horizontal quick-jump pills showing live counts for Cart, Bookings, RFQs, and Favorites.
3. **Tab Bar (`ActivityHubTabBar`)**: Clear active/inactive states with count badges across `Cart`, `Bookings`, `RFQ`, and `Favorites`.
4. **Search Bar (`ActivitySearchBar`)**: Instant filtering across the active tab's items.
5. **Tab Body (`IndexedStack`)**: Preserves scroll position and state per tab, with pull-to-refresh, skeleton loading, empty states, and error retry views.

## 3. Accessibility, RTL/LTR & Theme Support
- Minimum 44dp touch targets on navigation, quantity, and action buttons.
- `EdgeInsetsDirectional` and `AlignmentDirectional` used for seamless Arabic RTL and English LTR mirroring.
- Full Light and Dark mode token support verified across all cards, badges, sheets, and dialogs.
