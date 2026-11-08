class AuthUser {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isPhoneVerified;

  const AuthUser({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.isPhoneVerified,
  });
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}
