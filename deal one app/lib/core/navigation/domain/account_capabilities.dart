import 'package:flutter/foundation.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Authoritative navigation capabilities resolved strictly from Backend
/// session, account verification, account type, and member role permissions.
///
/// No synthetic backend roles or permissions are invented here; all rules
/// map directly to existing backend models (`Account`, `AccountMember`,
/// `AccountTenantGuard.resolveRolePermissions`, and V1 module availability).
enum NavigationCapability {
  none,
  authenticated,
  manageRealEstateListings,
  manageEngineeringServices,
  manageBuildingMaterialsProducts,
  manageAppliancesListings,
  manageAutomotiveMaintenanceServices,
  manageFashionListings,
  useSavedCart,
}

/// Visibility rule for a dynamic navigation item.
enum NavigationVisibilityRule {
  /// Always visible in the section bar.
  always,

  /// Visible only when the user does NOT have the section's seller capability.
  buyerOnly,

  /// Visible only when the user HAS the section's verified seller capability.
  sellerOnly,

  /// Visible only when the underlying backend capability/feature is supported.
  whenSupported,
}

/// Immutable snapshot of the current user's verified capabilities derived from
/// authoritative Backend account data (`GET /api/v1/accounts/my-accounts`).
@immutable
class AccountCapabilities {
  final bool isAuthenticated;
  final bool isLoading;
  final UserAccountEntity? activeAccount;
  final List<UserAccountEntity> accounts;

  /// Whether backend V1 Saved Basket (`GET/POST /api/v1/cart`) is enabled.
  /// Confirmed supported for Appliances & Decor and Fashion & Accessories
  /// (`commerceMode: V1_SAVED_BASKET`, `checkoutSupported: false`).
  final bool isCartSupported;

  const AccountCapabilities({
    required this.isAuthenticated,
    this.isLoading = false,
    this.activeAccount,
    this.accounts = const [],
    this.isCartSupported = true,
  });

  const AccountCapabilities.guest({this.isCartSupported = true})
      : isAuthenticated = false,
        isLoading = false,
        activeAccount = null,
        accounts = const [];

  const AccountCapabilities.loading({this.isCartSupported = true})
      : isAuthenticated = true,
        isLoading = true,
        activeAccount = null,
        accounts = const [];

  /// Resolves the authoritative backend role permissions matching
  /// `backend/src/modules/auth/guards/account-tenant.guard.ts`.
  static Set<String> permissionsForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case 'owner':
        return const {
          '*',
          'account:manage',
          'team:manage',
          'listings:manage',
          'listings:create',
          'listings:edit',
          'chat:respond',
        };
      case 'manager':
        return const {
          'team:view',
          'listings:manage',
          'listings:create',
          'listings:edit',
          'chat:respond',
        };
      case 'lister':
        return const {
          'listings:create',
          'listings:edit',
        };
      case 'responder':
        return const {
          'chat:respond',
        };
      default:
        return const {};
    }
  }

  /// Active account evaluated for seller permissions.
  UserAccountEntity? get effectiveAccount {
    if (!isAuthenticated) return null;
    if (activeAccount != null) return activeAccount;
    if (accounts.isEmpty) return null;
    for (final acc in accounts) {
      if (acc.isActive && acc.isVerified) return acc;
    }
    return accounts.first;
  }

  /// Resolved backend permissions for the active account membership.
  Set<String> get activePermissions {
    final acc = effectiveAccount;
    if (acc == null || !acc.isActive) return const {};
    return permissionsForRole(acc.role);
  }

  /// True when the active account is active, backend-verified (`approved`),
  /// and the user's membership role permits creating/managing listings.
  bool get hasVerifiedListingManagementRole {
    final acc = effectiveAccount;
    if (!isAuthenticated || acc == null) return false;
    if (!acc.isActive || !acc.isVerified) return false;
    final perms = permissionsForRole(acc.role);
    return perms.contains('*') ||
        perms.contains('listings:manage') ||
        perms.contains('listings:create');
  }

  /// True when the active account can respond to incoming bookings / RFQs
  /// (`owner`, `manager`, or `responder` on a verified active account).
  bool get canRespondAsProvider {
    final acc = effectiveAccount;
    if (!isAuthenticated || acc == null) return false;
    if (!acc.isActive || !acc.isVerified) return false;
    final perms = permissionsForRole(acc.role);
    return perms.contains('*') || perms.contains('chat:respond');
  }

  String get normalizedAccountType =>
      (effectiveAccount?.accountType ?? '').toLowerCase().trim();

  /// Category-specific seller activation derived strictly from existing
  /// backend `accountType` + `verificationStatus == 'approved'` + `isActive`
  /// + `AccountTenantGuard` role permissions.
  ///
  /// Note (Backend Gap): Backend `accounts` table does not yet persist an
  /// explicit per-category `activatedCategories[]` array; eligibility is
  /// derived strictly from existing authoritative backend account types.
  bool get canManageRealEstateListings =>
      hasVerifiedListingManagementRole &&
      const {'individual', 'office', 'company'}.contains(normalizedAccountType);

  bool get canManageEngineeringServices =>
      hasVerifiedListingManagementRole &&
      const {'individual', 'office', 'company'}.contains(normalizedAccountType);

  bool get canManageBuildingMaterialsProducts =>
      hasVerifiedListingManagementRole &&
      const {'company', 'factory', 'store'}.contains(normalizedAccountType);

  bool get canManageAppliancesListings =>
      hasVerifiedListingManagementRole &&
      const {'individual', 'store', 'company', 'factory'}
          .contains(normalizedAccountType);

  bool get canManageAutomotiveMaintenanceServices =>
      hasVerifiedListingManagementRole &&
      const {'company', 'store', 'office'}.contains(normalizedAccountType);

  bool get canManageFashionListings =>
      hasVerifiedListingManagementRole &&
      const {'individual', 'store', 'company', 'factory'}
          .contains(normalizedAccountType);

  /// Checks whether the user holds a specific [NavigationCapability].
  bool hasCapability(NavigationCapability capability) {
    switch (capability) {
      case NavigationCapability.none:
        return true;
      case NavigationCapability.authenticated:
        return isAuthenticated;
      case NavigationCapability.manageRealEstateListings:
        return canManageRealEstateListings;
      case NavigationCapability.manageEngineeringServices:
        return canManageEngineeringServices;
      case NavigationCapability.manageBuildingMaterialsProducts:
        return canManageBuildingMaterialsProducts;
      case NavigationCapability.manageAppliancesListings:
        return canManageAppliancesListings;
      case NavigationCapability.manageAutomotiveMaintenanceServices:
        return canManageAutomotiveMaintenanceServices;
      case NavigationCapability.manageFashionListings:
        return canManageFashionListings;
      case NavigationCapability.useSavedCart:
        return isCartSupported;
    }
  }

  /// Resolves the seller capability required for a given canonical category slug.
  static NavigationCapability sellerCapabilityForSection(String sectionId) {
    final normalized = MapCategoryRegistry.normalizeSlug(sectionId);
    switch (normalized) {
      case MapCategoryRegistry.realEstateSlug:
        return NavigationCapability.manageRealEstateListings;
      case MapCategoryRegistry.servicesSlug:
        return NavigationCapability.manageEngineeringServices;
      case MapCategoryRegistry.buildingMaterialsSlug:
        return NavigationCapability.manageBuildingMaterialsProducts;
      case MapCategoryRegistry.homeAppliancesSlug:
        return NavigationCapability.manageAppliancesListings;
      case MapCategoryRegistry.carsSlug:
        return NavigationCapability.manageAutomotiveMaintenanceServices;
      case MapCategoryRegistry.fashionSlug:
        return NavigationCapability.manageFashionListings;
      default:
        return NavigationCapability.none;
    }
  }

  /// Returns true if the current user is an activated seller/provider for [sectionId].
  bool isActivatedSellerForSection(String sectionId) {
    final cap = sellerCapabilityForSection(sectionId);
    if (cap == NavigationCapability.none) return false;
    return hasCapability(cap);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountCapabilities &&
        other.isAuthenticated == isAuthenticated &&
        other.isLoading == isLoading &&
        other.isCartSupported == isCartSupported &&
        other.effectiveAccount?.id == effectiveAccount?.id &&
        other.effectiveAccount?.accountType == effectiveAccount?.accountType &&
        other.effectiveAccount?.verificationStatus ==
            effectiveAccount?.verificationStatus &&
        other.effectiveAccount?.isActive == effectiveAccount?.isActive &&
        other.effectiveAccount?.role == effectiveAccount?.role;
  }

  @override
  int get hashCode => Object.hash(
        isAuthenticated,
        isLoading,
        isCartSupported,
        effectiveAccount?.id,
        effectiveAccount?.accountType,
        effectiveAccount?.verificationStatus,
        effectiveAccount?.isActive,
        effectiveAccount?.role,
      );
}
