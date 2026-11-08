class LogSanitizer {
  static const Set<String> sensitiveKeys = {
    'authorization',
    'token',
    'accesstoken',
    'refreshtoken',
    'password',
    'passcode',
    'otp',
    'code',
    'secret',
    'cvv',
    'cardnumber',
    'creditcard',
    'apikey',
    'phone',
    'mobile',
    'phonenumber',
  };

  static dynamic sanitize(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is Map) {
      final sanitizedMap = <String, dynamic>{};
      for (final entry in data.entries) {
        final keyString = entry.key.toString();
        final normalizedKey = keyString.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (sensitiveKeys.contains(normalizedKey)) {
          sanitizedMap[keyString] = '[REDACTED]';
        } else {
          sanitizedMap[keyString] = sanitize(entry.value);
        }
      }
      return sanitizedMap;
    }

    if (data is List) {
      return data.map((item) => sanitize(item)).toList();
    }

    if (data is String) {
      if (data.startsWith('Bearer ') || data.startsWith('bearer ')) {
        return 'Bearer [REDACTED]';
      }
    }

    return data;
  }
}
