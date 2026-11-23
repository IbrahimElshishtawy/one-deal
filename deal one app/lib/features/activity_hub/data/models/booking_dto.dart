import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';

class BookingDto {
  final String id;
  final String? listingId;
  final String title;
  final String? imageUrl;
  final String providerName;
  final String category;
  final String type;
  final String? bookingDate;
  final String? bookingTime;
  final String address;
  final String status;
  final String? referenceCode;
  final String? notes;
  final bool canCancel;
  final bool canContactProvider;
  final bool hasTracking;

  const BookingDto({
    required this.id,
    this.listingId,
    required this.title,
    this.imageUrl,
    required this.providerName,
    required this.category,
    required this.type,
    this.bookingDate,
    this.bookingTime,
    required this.address,
    required this.status,
    this.referenceCode,
    this.notes,
    this.canCancel = false,
    this.canContactProvider = true,
    this.hasTracking = false,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    String resolvedCategory = '';
    final rawCat = json['category'];
    if (rawCat is Map) {
      final parent = rawCat['parent'];
      resolvedCategory = (parent is Map ? parent['slug']?.toString() : null) ??
          rawCat['slug']?.toString() ??
          '';
    } else if (rawCat != null) {
      resolvedCategory = rawCat.toString();
    }

    return BookingDto(
      id: json['id']?.toString() ?? '',
      listingId: json['listingId']?.toString() ?? json['listing_id']?.toString(),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString(),
      providerName:
          json['providerName']?.toString() ??
          json['provider_name']?.toString() ??
          '',
      category: resolvedCategory,
      type: json['type']?.toString() ?? '',
      bookingDate:
          json['bookingDate']?.toString() ?? json['booking_date']?.toString(),
      bookingTime:
          json['bookingTime']?.toString() ?? json['booking_time']?.toString(),
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      referenceCode:
          json['referenceCode']?.toString() ??
          json['reference_code']?.toString(),
      notes: json['notes']?.toString(),
      canCancel: json['canCancel'] as bool? ?? json['can_cancel'] as bool? ?? false,
      canContactProvider:
          json['canContactProvider'] as bool? ??
          json['can_contact_provider'] as bool? ??
          true,
      hasTracking:
          json['hasTracking'] as bool? ?? json['has_tracking'] as bool? ?? false,
    );
  }

  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      listingId: listingId,
      title: title,
      imageUrl: imageUrl,
      providerName: providerName,
      category: BookingCategory.fromBackend(category),
      type: BookingType.fromBackend(type),
      bookingDate: bookingDate != null ? DateTime.tryParse(bookingDate!) : null,
      bookingTime: bookingTime,
      address: address,
      status: BookingStatus.fromBackend(status),
      rawStatus: status,
      referenceCode: referenceCode,
      notes: notes,
      canCancel: canCancel,
      canContactProvider: canContactProvider,
      hasTracking: hasTracking,
    );
  }
}
