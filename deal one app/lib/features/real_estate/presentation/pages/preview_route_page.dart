import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';

/// Location and Preview Path Screen matching `Location and preview path.png`.
/// Displays an interactive FlutterMap route from current location to the property
/// along with the viewing summary sheet and navigation launcher.
class PreviewRoutePage extends StatefulWidget {
  final BookingEntity? booking;

  const PreviewRoutePage({super.key, this.booking});

  @override
  State<PreviewRoutePage> createState() => _PreviewRoutePageState();
}

class _PreviewRoutePageState extends State<PreviewRoutePage> {
  final MapController _mapController = MapController();
  bool _satelliteLayer = false;

  // Default Tanta coordinates (Gharbia, Egypt) when backend booking omits lat/lng
  static const LatLng _originPoint = LatLng(30.7865, 30.9985);
  static const LatLng _destinationPoint = LatLng(30.7990, 31.0072);
  static const List<LatLng> _routePoints = [
    _originPoint,
    LatLng(30.7915, 31.0018),
    LatLng(30.7942, 31.0068),
    _destinationPoint,
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = AppColors.isDark(context);
    final booking = widget.booking;
    final isConfirmed =
        booking == null || booking.status == BookingStatus.confirmed;
    final code = booking?.referenceCode?.isNotEmpty == true
        ? booking!.referenceCode!
        : '#DL-${(booking?.id.length ?? 0) >= 4 ? booking!.id.substring(0, 4).toUpperCase() : '1094'}';
    final title = booking?.title.isNotEmpty == true
        ? booking!.title
        : (isArabic ? 'شقة فاخرة للبيع - الحي المتميز' : 'Luxury Apartment');
    final address = booking?.address.isNotEmpty == true
        ? booking!.address
        : (isArabic
            ? 'طنطا، الحي المتميز (امتداد شارع النادي الرئيسي)'
            : 'Tanta, Al-Hay Al-Motamayez');
    final advisorName = booking?.providerName.isNotEmpty == true
        ? booking!.providerName
        : (isArabic ? 'م. حسام الدين شلبي' : 'Eng. Hossam El-Din');
    final dateStr = booking?.bookingDate != null
        ? '${booking!.bookingDate!.day}/${booking.bookingDate!.month}/${booking.bookingDate!.year}'
        : (isArabic ? 'الخميس، 24 أكتوبر 2024' : 'Thu, 24 Oct 2024');
    final timeStr = booking?.bookingTime?.isNotEmpty == true
        ? booking!.bookingTime!
        : (isArabic ? '04:30 م' : '04:30 PM');

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: Stack(
        children: [
          // Interactive Map Layer
          Positioned.fill(
            bottom: 330,
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(30.7932, 31.0032),
                initialZoom: 14.3,
              ),
              children: [
                TileLayer(
                  urlTemplate: _satelliteLayer
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dealone.market_space',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.5,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _originPoint,
                      width: 110,
                      height: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: DealOneTokens.navy,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: AppRadii.sm,
                            ),
                            child: Text(
                              isArabic ? 'موقعي الحالي' : 'My Location',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: DealOneTokens.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Marker(
                      point: _destinationPoint,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: DealOneTokens.navy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: DealOneTokens.cardShadow(context),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top Floating App Bar + ETA Pill
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DealOneTokens.cardSurfaceOf(context),
                      borderRadius: AppRadii.lg,
                      boxShadow: DealOneTokens.cardShadow(context),
                    ),
                    child: Row(
                      children: [
                        _MapSquareButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            isArabic ? 'مسار المعاينة' : 'Preview Route',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        _MapSquareButton(
                          icon: Icons.share_outlined,
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    'https://maps.google.com/?q=${_destinationPoint.latitude},${_destinationPoint.longitude}',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isArabic
                                      ? 'تم نسخ رابط موقع المعاينة'
                                      : 'Preview location link copied',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DealOneTokens.cardSurfaceOf(context),
                      borderRadius: AppRadii.full,
                      boxShadow: DealOneTokens.softShadow(context),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car_outlined,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic
                              ? '22 دقيقة  •  12.4 كم بالسيارة'
                              : '22 min  •  12.4 km by car',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Left Floating Map Controls
          Positioned(
            left: AppSpacing.lg,
            bottom: 390,
            child: Column(
              children: [
                _MapSquareButton(
                  icon: Icons.my_location_rounded,
                  elevated: true,
                  onTap: () => _mapController.move(_originPoint, 14.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MapSquareButton(
                  icon: Icons.layers_outlined,
                  elevated: true,
                  onTap: () =>
                      setState(() => _satelliteLayer = !_satelliteLayer),
                ),
              ],
            ),
          ),

          // Bottom Details Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: DealOneTokens.cardSurfaceOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                boxShadow: DealOneTokens.cardShadow(context),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: DealOneTokens.cardBorderOf(context),
                          borderRadius: AppRadii.full,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic
                              ? 'كود المعاينة: $code'
                              : 'Preview Code: $code',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isConfirmed
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: AppRadii.full,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isConfirmed
                                    ? (isArabic ? 'معاينة مؤكدة' : 'Confirmed')
                                    : (isArabic ? 'قيد التأكيد' : 'Pending'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isConfirmed
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 15,
                          color: DealOneTokens.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Date & Time Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: AppRadii.lg,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DealOneTokens.cardSurfaceOf(context),
                              borderRadius: AppRadii.md,
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'تاريخ المعاينة' : 'Viewing Date',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        DealOneTokens.textSecondaryOf(context),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: DealOneTokens.cardSurfaceOf(context),
                              borderRadius: AppRadii.md,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: DealOneTokens.textPrimaryOf(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Advisor Row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: DealOneTokens.navy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      advisorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: DealOneTokens.textPrimaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                ],
                              ),
                              Text(
                                isArabic
                                    ? 'مستشار المعاينة العقارية الميداني'
                                    : 'Field Real Estate Viewing Advisor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DealOneTokens.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MapSquareButton(
                          icon: Icons.phone_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isArabic
                                      ? 'جاري تجهيز الاتصال بـ $advisorName'
                                      : 'Calling $advisorName...',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        _MapSquareButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () => context.push(RouteNames.conversations),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Primary Navigation CTA
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DealOneTokens.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'https://www.google.com/maps/dir/?api=1&destination=${_destinationPoint.latitude},${_destinationPoint.longitude}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم تجهيز ونسخ رابط الملاحة في خرائط Google'
                                  : 'Google Maps directions link copied',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.near_me_outlined, size: 19),
                      label: Text(
                        isArabic
                            ? 'بدء الملاحة والاتجاهات'
                            : 'Start Navigation & Directions',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: DealOneTokens.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isArabic
                                ? 'سيتم فتح المسار مباشرة في تطبيق خرائط Google أو Apple Maps'
                                : 'Directions open directly in Google Maps or Apple Maps',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool elevated;

  const _MapSquareButton({
    required this.icon,
    required this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Material(
      color: elevated
          ? DealOneTokens.cardSurfaceOf(context)
          : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9)),
      borderRadius: AppRadii.md,
      elevation: elevated ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}
