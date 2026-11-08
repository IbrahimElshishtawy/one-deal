class QuotaUsageDto {
  final String timezone;
  final String date;
  final int used;
  final int limit;
  final int remaining;
  final bool isLimitReached;

  const QuotaUsageDto({
    required this.timezone,
    required this.date,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.isLimitReached,
  });

  factory QuotaUsageDto.fromJson(Map<String, dynamic> json) {
    final cr = json['contactReveals'] as Map<String, dynamic>? ?? {};
    return QuotaUsageDto(
      timezone: json['timezone']?.toString() ?? 'Africa/Cairo',
      date: json['date']?.toString() ?? '',
      used: (cr['used'] as num?)?.toInt() ?? 0,
      limit: (cr['limit'] as num?)?.toInt() ?? 5,
      remaining: (cr['remaining'] as num?)?.toInt() ?? 0,
      isLimitReached: cr['isLimitReached'] == true || cr['is_limit_reached'] == true,
    );
  }
}
