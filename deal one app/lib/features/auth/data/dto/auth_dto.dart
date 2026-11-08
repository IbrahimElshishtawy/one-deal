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

class AuthUserDto {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final bool isPhoneVerified;

  const AuthUserDto({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.isPhoneVerified,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      isPhoneVerified: json['isPhoneVerified'] == true || json['is_phone_verified'] == true,
    );
  }
}

class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final AuthUserDto user;

  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken']?.toString() ?? json['access_token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? json['refresh_token']?.toString() ?? '',
      user: AuthUserDto.fromJson(
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : (json['user'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }
}
