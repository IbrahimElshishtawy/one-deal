class QuotaUsageEntity {
  final String timezone;
  final String date;
  final int used;
  final int limit;
  final int remaining;
  final bool isLimitReached;

  const QuotaUsageEntity({
    required this.timezone,
    required this.date,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.isLimitReached,
  });
}
