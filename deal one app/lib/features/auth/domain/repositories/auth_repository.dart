import '../entities/auth_session.dart';

/// Contract for authentication and profile hydration operations.
abstract class AuthRepository {
  /// Dispatches a verification OTP code to the normalized Egyptian [phone].
  Future<OtpDispatchResult> sendOtp(String phone);

  /// Requests a fresh OTP code for [phone] subject to backend cooldown limits.
  Future<OtpDispatchResult> resendOtp(String phone);

  /// Verifies the 6-digit [code] for [phone], stores JWT tokens securely,
  /// and returns the authenticated [AuthSession].
  Future<AuthSession> verifyOtp(String phone, String code);

  /// Authenticates using [phone] and [password] on `POST /auth/login`.
  Future<AuthSession> loginWithPassword(String phone, String password);

  /// Updates the authenticated user's profile (`PUT /users/me`).
  Future<AuthUser> updateProfile({required String fullName});

  /// Fetches the authenticated user's current profile (`GET /users/me`).
  Future<AuthUser?> fetchCurrentUser();

  /// Terminates the active session on the backend and clears stored tokens.
  Future<void> logout();

  /// Checks whether an access token is currently stored on the device.
  Future<bool> isAuthenticated();
}
