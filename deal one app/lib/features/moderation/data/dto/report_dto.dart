class CreateReportDto {
  final String? listingId;
  final String? reportedAccountId;
  final String? reportedUserId;
  final String reason; // scam, inappropriate, false_info, duplicate, prohibited, other
  final String? notes;
  final String? details;

  const CreateReportDto({
    this.listingId,
    this.reportedAccountId,
    this.reportedUserId,
    required this.reason,
    this.notes,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      if (listingId != null) 'listingId': listingId,
      if (reportedAccountId != null) 'reportedAccountId': reportedAccountId,
      if (reportedUserId != null) 'reportedUserId': reportedUserId,
      'reason': reason,
      if (notes != null) 'notes': notes,
      if (details != null) 'details': details,
    };
  }
}
