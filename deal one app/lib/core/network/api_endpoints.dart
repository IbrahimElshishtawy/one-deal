/// Authoritative API endpoint paths discovered and verified from OpenAPI 3.0 specification.
/// All paths are relative to the validated API global prefix (e.g. `/api/v1`).
class ApiEndpoints {
  // Health probes (Excluded from global prefix in server, resolved at origin root)
  static const String healthLive = '/health/live';
  static const String healthReady = '/health/ready';

  // Authentication & Sessions
  static const String sendOtp = '/auth/otp/send';
  static const String resendOtp = '/auth/otp/resend';
  static const String verifyOtp = '/auth/otp/verify';
  static const String login = '/auth/login';
  static const String setPassword = '/auth/password/set';
  static const String changePassword = '/auth/password/change';
  static const String forgotPassword = '/auth/password/forgot';
  static const String resetPassword = '/auth/password/reset';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String requestEmailVerification =
      '/auth/email/verification/request';
  static const String resendEmailVerification =
      '/auth/email/verification/resend';
  static const String verifyEmail = '/auth/email/verify';
  static const String devGuestLogin = '/auth/dev-guest';
  static const String activeSessions = '/auth/sessions';
  static const String terminateAllSessions = '/auth/sessions/terminate-all';

  // Users
  static const String userMe = '/users/me';

  // Accounts & Multi-tenancy
  static const String accounts = '/accounts';
  static const String myAccounts = '/accounts/my-accounts';
  static String accountById(String id) => '/accounts/$id';
  static String accountBranches(String id) => '/accounts/$id/branches';
  static String accountBranchDetail(String id, String branchId) =>
      '/accounts/$id/branches/$branchId';
  static String accountMembers(String id) => '/accounts/$id/members';
  static String inviteMember(String id) => '/accounts/$id/members/invite';
  static String removeMember(String id, String userId) =>
      '/accounts/$id/members/$userId';
  static String accountServiceAreas(String id) =>
      '/accounts/$id/service-areas';
  static String accountServiceAreaDetail(String id, String serviceAreaId) =>
      '/accounts/$id/service-areas/$serviceAreaId';
  static String accountVerifications(String id) =>
      '/accounts/$id/verifications';

  // Seller Verification & Business Upgrade
  static const String sellerApplicationRequirements =
      '/seller-applications/requirements';
  static const String sellerApplications = '/seller-applications';
  static const String sellerApplicationMe = '/seller-applications/me';
  static const String sellerApplicationMeCorrections =
      '/seller-applications/me/corrections';
  static const String sellerApplicationMeHistory =
      '/seller-applications/me/history';
  static const String sellerApplicationMeDocumentUploadUrl =
      '/seller-applications/me/documents/upload-url';
  static const String sellerApplicationMeDocuments =
      '/seller-applications/me/documents';
  static String sellerApplicationMeDocumentReplace(String documentId) =>
      '/seller-applications/me/documents/$documentId/replace';
  static String sellerApplicationMeDocumentAccess(String documentId) =>
      '/seller-applications/me/documents/$documentId/access';
  static String sellerApplicationMeDocumentDelete(String documentId) =>
      '/seller-applications/me/documents/$documentId';
  static const String sellerApplicationMeSubmit =
      '/seller-applications/me/submit';
  static const String sellerApplicationMeDevApprove =
      '/seller-applications/me/dev-approve';
  static const String sellerApplicationMeResubmit =
      '/seller-applications/me/resubmit';
  static const String sellerApplicationMeWithdraw =
      '/seller-applications/me/withdraw';
  static const String sellerApplicationMeRenew =
      '/seller-applications/me/renew';

  // Seller Center (Verified Sellers Only)
  static const String sellerCenterDashboard = '/seller-center/dashboard';
  static const String sellerCenterListings = '/seller-center/listings';
  static const String sellerCenterInteractions = '/seller-center/interactions';
  static const String sellerCenterConversations =
      '/seller-center/conversations';
  static const String sellerCenterDeals = '/seller-center/deals';
  static String sellerCenterDealById(String id) => '/seller-center/deals/$id';
  static const String sellerCenterAnalytics = '/seller-center/analytics';
  static const String sellerApplicationDashboard =
      '/seller-applications/dashboard';
  static const String sellerBusinessUpgrade =
      '/seller-applications/me/business-upgrade';
  static const String sellerBusinessUpgradeSubmit =
      '/seller-applications/me/business-upgrade/submit';
  static const String sellerBusinessUpgradeResubmit =
      '/seller-applications/me/business-upgrade/resubmit';

  // Categories & Dynamic Attributes
  static const String categories = '/categories';
  static String categoryBySlug(String slug) => '/categories/$slug';
  static String categoryFields(String slug) => '/categories/$slug/fields';

  // Geographic Locations
  static const String governorates = '/locations/governorates';
  static String cityAreas(int cityId) => '/locations/cities/$cityId/areas';

  // Listings Lifecycle & Contact Reveal
  static const String listings = '/listings';
  static const String batchPrices = '/listings/prices/batch';
  static const String home = '/home';
  static const String homeFeatured = '/home/featured';
  static const String homeLatest = '/home/latest';
  static const String homeRecommended = '/home/recommended';
  static const String homeCategories = '/home/categories';
  static String homeSection(String slug) => '/home/sections/$slug';
  static String listingDetails(String id) => '/listings/$id';
  static String listingAvailability(String id) => '/listings/$id/availability';
  static String listingStatus(String id) => '/listings/$id/status';
  static String submitForModeration(String id) => '/listings/$id/submit';
  static String contactSeller(String id) => '/listings/$id/contact';
  static String revealContact(String id) => '/listings/$id/reveal-contact';

  // Search
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteItem(String listingId) => '/favorites/$listingId';

  // Bookings & Appointments
  static const String bookings = '/bookings';
  static String bookingById(String id) => '/bookings/$id';
  static String bookingCancel(String id) => '/bookings/$id/cancel';
  static String bookingStatus(String id) => '/bookings/$id/status';

  // RFQ & Quotations
  static const String rfqs = '/rfqs';
  static String rfqById(String id) => '/rfqs/$id';
  static String rfqQuotations(String id) => '/rfqs/$id/quotations';
  static String quotationStatus(String id) => '/quotations/$id/status';

  // Cart (V1 Saved Basket)
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String id) => '/cart/items/$id';

  // Media
  static const String imageUploadUrls = '/media/images/upload-url';
  static const String confirmUpload = '/media/confirm-upload';

  // Quotas
  static const String myQuotas = '/quotas/my-usage';

  // Trust & Safety / Reporting
  static const String reports = '/reports';

  // Conversations & Chat
  static const String conversations = '/conversations';
  static const String conversationsStream = '/conversations/stream';
  static String conversationMessages(String id) => '/conversations/$id/messages';

  // Video Feed / Reels
  static const String videoFeed = '/video-feed';
  static const String videoUploadToken = '/media/video/upload-token';

  // Push Notifications & Inbox
  static const String notifications = '/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String deviceToken = '/notifications/device-token';

  // Admin: Settings, Verifications & Staff Management
  static const String adminSettings = '/admin/settings';
  static String adminSettingByKey(String key) => '/admin/settings/$key';
  static const String adminModerationVerifications =
      '/admin/moderation/verifications';
  static String adminModerationVerificationDecision(String id) =>
      '/admin/moderation/verifications/$id/decision';
  static const String adminStaffRoles = '/admin/staff/roles';
  static const String adminStaff = '/admin/staff';
  static String adminStaffById(String id) => '/admin/staff/$id';
}
