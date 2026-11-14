class SendOtpRequestDto {
  final String phone;

  const SendOtpRequestDto({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

class VerifyOtpRequestDto {
  final String phone;
  final String code;

  const VerifyOtpRequestDto({required this.phone, required this.code});

  Map<String, dynamic> toJson() => {'phone': phone, 'code': code};
}

class LoginPasswordRequestDto {
  final String phone;
  final String password;

  const LoginPasswordRequestDto({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

class RefreshTokenRequestDto {
  final String refreshToken;

  const RefreshTokenRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
        'refresh_token': refreshToken,
      };
}

class UpdateProfileRequestDto {
  final String fullName;

  const UpdateProfileRequestDto({required this.fullName});

  Map<String, dynamic> toJson() => {'fullName': fullName};
}

class OtpDispatchResponseDto {
  final bool success;
  final String message;
  final int cooldownSeconds;
  final int otpExpirySeconds;

  const OtpDispatchResponseDto({
    required this.success,
    required this.message,
    required this.cooldownSeconds,
    required this.otpExpirySeconds,
  });

  factory OtpDispatchResponseDto.fromJson(Map<String, dynamic> json) {
    final rawCooldown = json['cooldownSeconds'] ?? json['cooldown_seconds'];
    final rawExpiry = json['otpExpirySeconds'] ??
        json['otp_expiry_seconds'] ??
        json['expiresIn'] ??
        json['expires_in'];

    return OtpDispatchResponseDto(
      success: json['success'] != false,
      message: json['message']?.toString().trim().isNotEmpty == true
          ? json['message'].toString()
          : 'تم إرسال رمز التحقق بنجاح',
      cooldownSeconds: _parsePositiveInt(rawCooldown, fallback: 60),
      otpExpirySeconds: _parsePositiveInt(rawExpiry, fallback: 180),
    );
  }
}

class AuthUserDto {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final String? preferredLanguage;
  final String? role;

  const AuthUserDto({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.isPhoneVerified,
    this.preferredLanguage,
    this.role,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName:
          json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      isPhoneVerified:
          json['isPhoneVerified'] == true || json['is_phone_verified'] == true,
      preferredLanguage: json['preferredLanguage']?.toString() ??
          json['preferred_language']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class ActiveAccountSummaryDto {
  final String id;
  final String accountType;
  final String displayName;
  final String verificationStatus;
  final String role;

  const ActiveAccountSummaryDto({
    required this.id,
    required this.accountType,
    required this.displayName,
    required this.verificationStatus,
    required this.role,
  });

  factory ActiveAccountSummaryDto.fromJson(Map<String, dynamic> json) {
    return ActiveAccountSummaryDto(
      id: json['id']?.toString() ?? '',
      accountType: json['accountType']?.toString() ??
          json['account_type']?.toString() ??
          'individual',
      displayName: json['displayName']?.toString() ??
          json['display_name']?.toString() ??
          '',
      verificationStatus: json['verificationStatus']?.toString() ??
          json['verification_status']?.toString() ??
          'approved',
      role: json['role']?.toString() ?? 'owner',
    );
  }
}

class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;
  final ActiveAccountSummaryDto? activeAccount;
  final int? expiresIn;
  final String? sessionId;

  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.activeAccount,
    this.expiresIn,
    this.sessionId,
  });

  /// Parses both live NestJS responses (`tokens: { accessToken, refreshToken }`)
  /// and legacy flat token payloads.
  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final nestedTokens = _asStringKeyedMap(json['tokens']);
    final tokenSource = nestedTokens.isNotEmpty ? nestedTokens : json;

    final userMap = _asStringKeyedMap(json['user']);
    final accountMap = _asStringKeyedMap(
      json['activeAccount'] ?? json['active_account'],
    );

    final rawExpiresIn =
        tokenSource['expiresIn'] ?? tokenSource['expires_in'] ?? json['expiresIn'];

    return AuthResponseDto(
      accessToken: tokenSource['accessToken']?.toString() ??
          tokenSource['access_token']?.toString() ??
          '',
      refreshToken: tokenSource['refreshToken']?.toString() ??
          tokenSource['refresh_token']?.toString() ??
          '',
      user: AuthUserDto.fromJson(userMap),
      activeAccount: accountMap.isEmpty
          ? null
          : ActiveAccountSummaryDto.fromJson(accountMap),
      expiresIn: rawExpiresIn is int
          ? rawExpiresIn
          : int.tryParse(rawExpiresIn?.toString() ?? ''),
      sessionId: tokenSource['sessionId']?.toString() ??
          tokenSource['session_id']?.toString(),
    );
  }
}

Map<String, dynamic> _asStringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

int _parsePositiveInt(dynamic raw, {required int fallback}) {
  if (raw is int && raw > 0) {
    return raw;
  }
  final parsed = int.tryParse(raw?.toString() ?? '');
  if (parsed != null && parsed > 0) {
    return parsed;
  }
  return fallback;
}
