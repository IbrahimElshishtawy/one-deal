import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<void> resendOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String code);
  Future<AuthSession> loginWithPassword(String phone, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
}
