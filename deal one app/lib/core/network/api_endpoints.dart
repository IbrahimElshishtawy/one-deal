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
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authMe = '/auth/me';
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

  // Categories & Dynamic Attributes
  static const String categories = '/categories';
  static String categoryBySlug(String slug) => '/categories/$slug';
  static String categoryFields(String slug) => '/categories/$slug/fields';

  // Geographic Locations
  static const String governorates = '/locations/governorates';
  static String cityAreas(int cityId) => '/locations/cities/$cityId/areas';

  // Listings Lifecycle & Contact Reveal
  static const String listings = '/listings';
  static String listingDetails(String id) => '/listings/$id';
  static String listingAvailability(String id) => '/listings/$id/availability';
  static String listingStatus(String id) => '/listings/$id/status';
  static String submitForModeration(String id) => '/listings/$id/submit';
  static String contactSeller(String id) => '/listings/$id/contact';
  static String revealContact(String id) => '/listings/$id/reveal-contact';

  // Search
  static const String search = '/search';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteItem(String listingId) => '/favorites/$listingId';

  // Media
  static const String imageUploadUrls = '/media/images/upload-url';
  static const String confirmUpload = '/media/confirm-upload';

  // Quotas
  static const String myQuotas = '/quotas/my-usage';

  // Trust & Safety / Reporting
  static const String reports = '/reports';

  // Conversations & Chat
  static const String conversations = '/conversations';
  static String conversationMessages(String id) => '/conversations/$id/messages';

  // Push Notifications
  static const String deviceToken = '/notifications/device-token';
}
