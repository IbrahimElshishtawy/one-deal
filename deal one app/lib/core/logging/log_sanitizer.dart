class LogSanitizer {
  static const int maxStringPreviewLength = 500;
  static const int maxListPreviewItems = 8;

  static const Set<String> sensitiveKeys = {
    'authorization',
    'token',
    'accesstoken',
    'refreshtoken',
    'verificationtoken',
    'emailtoken',
    'password',
    'currentpassword',
    'newpassword',
    'passwordhash',
    'passcode',
    'otp',
    'code',
    'codehash',
    'secret',
    'cvv',
    'cardnumber',
    'creditcard',
    'apikey',
    'xapikey',
    'cookie',
    'setcookie',
    'messagecontent',
    'chatbody',
  };

  static String maskEmail(String email) {
    final trimmed = email.trim();
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0) return '***';
    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    final visible = local.length <= 3 ? local.substring(0, 1) : local.substring(0, 3);
    return '$visible***$domain';
  }

  static String maskPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.length <= 6) return '***';
    return '${trimmed.substring(0, 5)}***${trimmed.substring(trimmed.length - 4)}';
  }

  static dynamic sanitize(dynamic data, {int depth = 0}) {
    if (data == null || depth > 6) {
      return data;
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
        } else if (normalizedKey == 'email' && entry.value is String) {
          sanitizedMap[keyString] = maskEmail(entry.value as String);
        } else if ((normalizedKey == 'phone' ||
                normalizedKey == 'mobile' ||
                normalizedKey == 'phonenumber') &&
            entry.value is String) {
          sanitizedMap[keyString] = maskPhone(entry.value as String);
        } else {
          sanitizedMap[keyString] = sanitize(entry.value, depth: depth + 1);
        }
      }
      return sanitizedMap;
    }

    if (data is List) {
      if (data.length > maxListPreviewItems) {
        final preview = data
            .take(maxListPreviewItems)
            .map((item) => sanitize(item, depth: depth + 1))
            .toList();
        preview.add('... (${data.length - maxListPreviewItems} more items)');
        return preview;
      }
      return data.map((item) => sanitize(item, depth: depth + 1)).toList();
    }

    if (data is String) {
      if (data.startsWith('Bearer ') || data.startsWith('bearer ')) {
        return 'Bearer [REDACTED]';
      }
      if (data.length > maxStringPreviewLength) {
        return '${data.substring(0, maxStringPreviewLength)}...[truncated]';
      }
    }

    return data;
  }
}
