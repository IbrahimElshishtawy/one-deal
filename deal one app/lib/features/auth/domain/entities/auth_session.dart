/// Represents whether an OTP verification session originated from Sign Up or Login.
enum AuthFlowMode { signUp, login }

/// External social providers shown in the UI.
enum SocialAuthProviderType { google, apple }

/// Legal document screens accessible from Sign Up.
enum LegalDocumentType { termsOfService, privacyPolicy }

/// Authenticated user domain entity.
class AuthUser {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String? preferredLanguage;
  final String? role;

  const AuthUser({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.isPhoneVerified,
    this.isEmailVerified = false,
    this.preferredLanguage,
    this.role,
  });

  AuthUser copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    String? preferredLanguage,
    String? role,
  }) {
    return AuthUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      role: role ?? this.role,
    );
  }
}

/// Active workspace/account summary returned alongside authentication.
class ActiveAccountSummary {
  final String id;
  final String accountType;
  final String displayName;
  final String verificationStatus;
  final String role;

  const ActiveAccountSummary({
    required this.id,
    required this.accountType,
    required this.displayName,
    required this.verificationStatus,
    required this.role,
  });
}

/// Authenticated session including JWT pair, user, and optional active account.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  final ActiveAccountSummary? activeAccount;
  final int? expiresIn;
  final String? sessionId;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.activeAccount,
    this.expiresIn,
    this.sessionId,
  });

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    AuthUser? user,
    ActiveAccountSummary? activeAccount,
    int? expiresIn,
    String? sessionId,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      activeAccount: activeAccount ?? this.activeAccount,
      expiresIn: expiresIn ?? this.expiresIn,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// Backend response metadata for `POST /auth/otp/send` and `POST /auth/otp/resend`.
class OtpDispatchResult {
  final bool success;
  final String message;
  final int cooldownSeconds;
  final int otpExpirySeconds;
  final String? deliveryChannel;
  final bool? whatsappAvailable;
  final String? errorCode;

  const OtpDispatchResult({
    this.success = true,
    this.message = 'تم إرسال رمز التحقق بنجاح',
    this.cooldownSeconds = 60,
    this.otpExpirySeconds = 180,
    this.deliveryChannel,
    this.whatsappAvailable,
    this.errorCode,
  });
}

/// Carries flow context when navigating into the OTP Verification screen.
class PendingAuthContext {
  final String normalizedPhone;
  final String displayPhone;
  final String? pendingFullName;
  final AuthFlowMode flowMode;
  final int cooldownSeconds;
  final int otpExpirySeconds;
  final String? redirectTo;

  const PendingAuthContext({
    required this.normalizedPhone,
    required this.displayPhone,
    this.pendingFullName,
    required this.flowMode,
    this.cooldownSeconds = 60,
    this.otpExpirySeconds = 180,
    this.redirectTo,
  });

  PendingAuthContext copyWith({
    String? normalizedPhone,
    String? displayPhone,
    String? pendingFullName,
    AuthFlowMode? flowMode,
    int? cooldownSeconds,
    int? otpExpirySeconds,
    String? redirectTo,
  }) {
    return PendingAuthContext(
      normalizedPhone: normalizedPhone ?? this.normalizedPhone,
      displayPhone: displayPhone ?? this.displayPhone,
      pendingFullName: pendingFullName ?? this.pendingFullName,
      flowMode: flowMode ?? this.flowMode,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      otpExpirySeconds: otpExpirySeconds ?? this.otpExpirySeconds,
      redirectTo: redirectTo ?? this.redirectTo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingAuthContext &&
        other.normalizedPhone == normalizedPhone &&
        other.displayPhone == displayPhone &&
        other.pendingFullName == pendingFullName &&
        other.flowMode == flowMode &&
        other.cooldownSeconds == cooldownSeconds &&
        other.otpExpirySeconds == otpExpirySeconds &&
        other.redirectTo == redirectTo;
  }

  @override
  int get hashCode => Object.hash(
    normalizedPhone,
    displayPhone,
    pendingFullName,
    flowMode,
    cooldownSeconds,
    otpExpirySeconds,
    redirectTo,
  );
}
