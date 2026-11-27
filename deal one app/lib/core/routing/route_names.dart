class RouteNames {
  static const String splash = '/splash';
  static const String root = '/';
  static const String realEstate = '/real-estate';
  static const String realEstateDetail = '/real-estate/detail';
  static const String homeServices = '/home-services';
  static const String homeAppliances = '/home-appliances';
  static const String applianceCategoryListing = '/home-appliances/category';
  static const String buildingMaterials = '/building-materials';
  static const String steelRebarListing = '/building-materials/steel-rebar';
  static const String buildingMaterialCategoryDetail =
      '/building-materials/category-detail';
  static const String buildingMaterialsCategories =
      '/building-materials/categories';
  static const String buildingMaterialsCart = '/building-materials/cart';
  static const String buildingMaterialsCheckout =
      '/building-materials/checkout';
  static const String buildingMaterialsOrders = '/building-materials/orders';
  static const String buildingMaterialsOrderDetail =
      '/building-materials/orders/detail';
  static const String buildingMaterialsNotifications =
      '/building-materials/notifications';
  static const String buildingMaterialsProductDetail =
      '/building-materials/product-detail';
  static const String buildingMaterialsRfq = '/building-materials/rfq';
  static const String acServiceDetail = '/home-services/ac-service-detail';
  static const String homeServicesCatalog = '/home-services/catalog';
  static const String homeServicesBookings = '/home-services/bookings';
  static const String homeServicesFavorites = '/home-services/favorites';
  static const String homeServicesNotifications =
      '/home-services/notifications';
  static const String homeServiceDetail = '/home-services/service-detail';
  static const String homeServiceProviderDetail =
      '/home-services/provider-detail';
  static const String homeServicesBookingWizard = '/home-services/book';
  static const String homeServicesBookingDetail =
      '/home-services/booking-detail';
  static const String homeServicesTechnicianTracking =
      '/home-services/tracking';

  static const String cars = '/cars';
  static const String carsDetail = '/cars/detail';
  static const String carsBrowse = '/cars/browse';
  static const String fashion = '/fashion';
  static const String fashionDetail = '/fashion/detail';
  static const String fashionCart = '/fashion/cart';
  static const String fashionCategories = '/fashion/categories';

  static const String explore = '/explore';
  static const String myActivity = '/my-activity';
  static const String activityHub = '/activity-hub';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String editAccount = '/profile/edit';
  static const String conversations = '/conversations';
  static const String chatSettings = '/conversations/settings';
  static const String conversationChat = '/conversations/:id';
  static const String realEstateMap = '/real-estate/map';
  static const String activePreviews = '/real-estate/previews';
  static const String previewRoute = '/real-estate/previews/route';
  static const String categoryMap = '/map/:categorySlug';
  static String categoryMapFor(String slug) => '/map/$slug';
  static const String sectionCategories = '/categories/:categorySlug';
  static String sectionCategoriesFor(String slug) => '/categories/$slug';
  static const String sellerManagement = '/seller/:categorySlug/:mode';
  static String sellerManagementFor(String slug, String mode) =>
      '/seller/$slug/$mode';
  static const String createListing = '/listings/create';
  static String createListingFor(String slug, {String? listingKind}) {
    final params = <String, String>{'category': slug};
    if (listingKind != null && listingKind.isNotEmpty) {
      params['kind'] = listingKind;
    }
    return Uri(path: createListing, queryParameters: params).toString();
  }
  static String activityHubFor({required String tab, String? categorySlug}) {
    final params = <String, String>{'tab': tab};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      params['category'] = categorySlug;
    }
    return Uri(path: activityHub, queryParameters: params).toString();
  }

  /// Returns true if [location] targets one of the 4 branches hosted inside
  /// GoRouter's [StatefulShellRoute] (`root`, `favorites`, `activityHub`, `profile`).
  ///
  /// Shell branch routes must be navigated via `context.go` / `context.goNamed`
  /// (never `push` / `pushNamed`) to avoid duplicate Navigator GlobalKey crashes.
  static bool isShellBranchLocation(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return path == root ||
        path == favorites ||
        path == activityHub ||
        path == profile;
  }

  /// Returns true if [routeName] targets one of the 4 [StatefulShellRoute] branches.
  static bool isShellBranchName(String routeName) {
    return routeName == rootName ||
        routeName == favoritesName ||
        routeName == activityHubName ||
        routeName == profileName;
  }
  static const String realEstateGallery = '/real-estate/gallery/:id';
  static const String realEstateReels = '/real-estate/reels';
  static const String search = '/search';
  static const String listingDetail = '/listings/:id';
  static const String onboarding = '/onboarding';
  static const String signUp = '/sign-up';
  static const String otpVerification = '/otp-verification';
  static const String verificationSuccess = '/verification-success';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String login = '/login';
  static const String globalNotifications = '/notifications';
  static const String notFound = '/not-found';

  // Seller Verification & Business Upgrade Flow
  static const String sellerVerification = '/seller-verification';
  static const String sellerVerificationType = '/seller-verification/type';
  static const String sellerVerificationInfo = '/seller-verification/info';
  static const String sellerVerificationRequirements =
      '/seller-verification/requirements';
  static const String sellerVerificationUpload = '/seller-verification/upload';
  static const String sellerVerificationReview = '/seller-verification/review';
  static const String sellerVerificationSuccess =
      '/seller-verification/success';
  static const String sellerVerificationTracking =
      '/seller-verification/tracking';
  static const String sellerVerificationProfile =
      '/seller-verification/profile';
  static const String sellerVerificationUpgrade =
      '/seller-verification/upgrade';
  static const String sellerCenter = '/seller-center';

  static const String searchName = 'search';
  static const String listingDetailName = 'listing_detail';
  static const String onboardingName = 'onboarding';
  static const String signUpName = 'sign_up';
  static const String otpVerificationName = 'otp_verification';
  static const String verificationSuccessName = 'verification_success';
  static const String termsName = 'terms';
  static const String privacyName = 'privacy';
  static const String loginName = 'login';

  static const String splashName = 'splash';
  static const String rootName = 'root';
  static const String realEstateName = 'real_estate';
  static const String realEstateDetailName = 'real_estate_detail';
  static const String homeServicesName = 'home_services';
  static const String homeAppliancesName = 'home_appliances';
  static const String applianceCategoryListingName =
      'appliance_category_listing';
  static const String buildingMaterialsName = 'building_materials';
  static const String steelRebarListingName = 'steel_rebar_listing';
  static const String buildingMaterialCategoryDetailName =
      'building_material_category_detail';
  static const String buildingMaterialsCategoriesName =
      'building_materials_categories';
  static const String buildingMaterialsCartName = 'building_materials_cart';
  static const String buildingMaterialsCheckoutName =
      'building_materials_checkout';
  static const String buildingMaterialsOrdersName = 'building_materials_orders';
  static const String buildingMaterialsOrderDetailName =
      'building_materials_order_detail';
  static const String buildingMaterialsNotificationsName =
      'building_materials_notifications';
  static const String buildingMaterialsProductDetailName =
      'building_materials_product_detail';
  static const String buildingMaterialsRfqName = 'building_materials_rfq';
  static const String acServiceDetailName = 'ac_service_detail';
  static const String homeServicesCatalogName = 'home_services_catalog';
  static const String homeServicesBookingsName = 'home_services_bookings';
  static const String homeServicesFavoritesName = 'home_services_favorites';
  static const String homeServicesNotificationsName =
      'home_services_notifications';
  static const String homeServiceDetailName = 'home_service_detail';
  static const String homeServiceProviderDetailName =
      'home_service_provider_detail';
  static const String homeServicesBookingWizardName =
      'home_services_booking_wizard';
  static const String homeServicesBookingDetailName =
      'home_services_booking_detail';
  static const String homeServicesTechnicianTrackingName =
      'home_services_technician_tracking';
  static const String carsName = 'cars';
  static const String carsDetailName = 'cars_detail';
  static const String carsBrowseName = 'cars_browse';
  static const String fashionName = 'fashion';
  static const String fashionDetailName = 'fashion_detail';
  static const String fashionCartName = 'fashion_cart';
  static const String fashionCategoriesName = 'fashion_categories';
  static const String exploreName = 'explore';
  static const String myActivityName = 'my_activity';
  static const String activityHubName = 'activity_hub';
  static const String favoritesName = 'favorites';
  static const String profileName = 'profile';
  static const String editAccountName = 'edit_account';
  static const String conversationsName = 'conversations';
  static const String chatSettingsName = 'chat_settings';
  static const String conversationChatName = 'conversation_chat';
  static const String realEstateMapName = 'real_estate_map';
  static const String activePreviewsName = 'active_previews';
  static const String previewRouteName = 'preview_route';
  static const String categoryMapName = 'category_map';
  static const String sectionCategoriesName = 'section_categories';
  static const String sellerManagementName = 'seller_management';
  static const String createListingName = 'create_listing';
  static const String realEstateGalleryName = 'real_estate_gallery';
  static const String realEstateReelsName = 'real_estate_reels';
  static const String globalNotificationsName = 'global_notifications';
  static const String notFoundName = 'not_found';

  static const String sellerVerificationName = 'seller_verification';
  static const String sellerVerificationTypeName = 'seller_verification_type';
  static const String sellerVerificationInfoName = 'seller_verification_info';
  static const String sellerVerificationRequirementsName =
      'seller_verification_requirements';
  static const String sellerVerificationUploadName =
      'seller_verification_upload';
  static const String sellerVerificationReviewName =
      'seller_verification_review';
  static const String sellerVerificationSuccessName =
      'seller_verification_success';
  static const String sellerVerificationTrackingName =
      'seller_verification_tracking';
  static const String sellerVerificationProfileName =
      'seller_verification_profile';
  static const String sellerVerificationUpgradeName =
      'seller_verification_upgrade';
  static const String sellerCenterName = 'seller_center';
}
