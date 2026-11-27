import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_request_sheet.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

enum _PreviewFilter { upcoming, confirmed, pending }

/// Active Property Previews Screen matching `Active Preview.png`.
/// Connected to `bookingsProvider` (`GET /bookings`, `PATCH /bookings/:id/cancel`).
class ActivePreviewsPage extends ConsumerStatefulWidget {
  const ActivePreviewsPage({super.key});

  @override
  ConsumerState<ActivePreviewsPage> createState() => _ActivePreviewsPageState();
}

class _ActivePreviewsPageState extends ConsumerState<ActivePreviewsPage> {
  _PreviewFilter _selectedFilter = _PreviewFilter.upcoming;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).loadBookings();
    });
  }

  List<BookingEntity> _filterBookings(List<BookingEntity> all) {
    final active = all
        .where(
          (b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.rejected,
        )
        .toList();
    return switch (_selectedFilter) {
      _PreviewFilter.upcoming => active,
      _PreviewFilter.confirmed =>
        active.where((b) => b.status == BookingStatus.confirmed).toList(),
      _PreviewFilter.pending =>
        active.where((b) => b.status == BookingStatus.pending).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final bookingsState = ref.watch(bookingsProvider);
    final allItems = bookingsState.items.valueOrNull ?? const <BookingEntity>[];
    final activeItems = allItems
        .where(
          (b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.rejected,
        )
        .toList();
    final confirmedCount =
        activeItems.where((b) => b.status == BookingStatus.confirmed).length;
    final pendingCount =
        activeItems.where((b) => b.status == BookingStatus.pending).length;
    final visibleItems = _filterBookings(allItems);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: DealOneTokens.navy,
          onRefresh: () =>
              ref.read(bookingsProvider.notifier).loadBookings(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top App Bar: Back + Title + "+ حجز معاينة" pill
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop()) ...[
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          isArabic ? 'المعاينات النشطة' : 'Active Previews',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DealOneTokens.navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.full,
                          ),
                        ),
                        onPressed: () => _openNewPreviewSheet(context),
                        icon: const Icon(Icons.add_circle_outline, size: 17),
                        label: Text(
                          isArabic ? 'حجز معاينة' : 'Book Preview',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Chips Row
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _FilterPill(
                        label: isArabic ? 'القادمة' : 'Upcoming',
                        dotColor: Colors.white,
                        isSelected: _selectedFilter == _PreviewFilter.upcoming,
                        onTap: () => setState(
                          () => _selectedFilter = _PreviewFilter.upcoming,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterPill(
                        label: isArabic
                            ? 'مؤكدة ($confirmedCount)'
                            : 'Confirmed ($confirmedCount)',
                        dotColor: const Color(0xFF10B981),
                        isSelected: _selectedFilter == _PreviewFilter.confirmed,
                        onTap: () => setState(
                          () => _selectedFilter = _PreviewFilter.confirmed,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterPill(
                        label: isArabic
                            ? 'بانتظار التأكيد ($pendingCount)'
                            : 'Pending ($pendingCount)',
                        dotColor: const Color(0xFFF59E0B),
                        isSelected: _selectedFilter == _PreviewFilter.pending,
                        onTap: () => setState(
                          () => _selectedFilter = _PreviewFilter.pending,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content
              if (bookingsState.items.isLoading && allItems.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: DealOneDotLoader(dotSize: 9)),
                )
              else if (bookingsState.items.hasError && allItems.isEmpty)
                SliverFillRemaining(
                  child: DealOneErrorStateView(
                    error: bookingsState.items.error!,
                    onRetry: () => ref
                        .read(bookingsProvider.notifier)
                        .loadBookings(refresh: true),
                  ),
                )
              else if (visibleItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DealOneEmptyStateView(
                          icon: Icons.event_available_outlined,
                          title: isArabic
                              ? 'لا توجد معاينات نشطة حالياً'
                              : 'No Active Previews Yet',
                          description: isArabic
                              ? 'يمكنك حجز معاينة لأي عقار ومتابعة الموعد والمسار من هنا.'
                              : 'Book a property viewing and track your schedule and directions here.',
                          actionLabel:
                              isArabic ? 'حجز معاينة جديدة' : 'Book a Preview',
                          actionIcon: Icons.add_rounded,
                          onAction: () => _openNewPreviewSheet(context),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FlexibilityPolicyCard(isArabic: isArabic),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == visibleItems.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: _FlexibilityPolicyCard(isArabic: isArabic),
                          );
                        }
                        final booking = visibleItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _ActivePreviewCard(
                            booking: booking,
                            isArabic: isArabic,
                            onOpenRoute: () => context.push(
                              RouteNames.previewRoute,
                              extra: booking,
                            ),
                            onReschedule: () =>
                                _openNewPreviewSheet(context, initial: booking),
                            onCancel: () => _confirmCancel(booking, isArabic),
                          ),
                        );
                      },
                      childCount: visibleItems.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewPreviewSheet(BuildContext context, {BookingEntity? initial}) {
    BookingRequestSheet.show(
      context,
      listingId: initial?.listingId,
      title: initial?.title ?? 'معاينة عقارية',
      providerName: initial?.providerName ?? 'مستشار المعاينة العقارية',
      category: BookingCategory.realEstate,
      defaultType: BookingType.propertyViewing,
    );
  }

  Future<void> _confirmCancel(BookingEntity booking, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'إلغاء الموعد' : 'Cancel Appointment'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إلغاء موعد المعاينة لـ "${booking.title}"؟'
              : 'Are you sure you want to cancel your viewing for "${booking.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isArabic ? 'تراجع' : 'Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isArabic ? 'إلغاء الموعد' : 'Cancel Viewing'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
    }
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Material(
      color: isSelected
          ? DealOneTokens.navy
          : (isDark ? AppColors.darkSurface : Colors.white),
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: isSelected
                  ? DealOneTokens.navy
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePreviewCard extends StatelessWidget {
  final BookingEntity booking;
  final bool isArabic;
  final VoidCallback onOpenRoute;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const _ActivePreviewCard({
    required this.booking,
    required this.isArabic,
    required this.onOpenRoute,
    required this.onReschedule,
    required this.onCancel,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return isArabic ? 'قريباً' : 'Scheduled';
    final d = dt.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isDark = AppColors.isDark(context);
    final code = booking.referenceCode?.isNotEmpty == true
        ? booking.referenceCode!
        : '#DL-${booking.id.length >= 4 ? booking.id.substring(0, 4).toUpperCase() : booking.id}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status pill + Reference code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    const SizedBox(width: 6),
                    Text(
                      isConfirmed
                          ? (isArabic ? 'معاينة مؤكدة' : 'Confirmed Preview')
                          : (isArabic
                              ? 'بإنتظار تأكيد المالك'
                              : 'Awaiting Owner Confirmation'),
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
              Text(
                code,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Property thumbnail + title + location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.md,
                child: booking.imageUrl != null && booking.imageUrl!.isNotEmpty
                    ? Image.network(
                        booking.imageUrl!,
                        width: 84,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _PlaceholderThumb(),
                      )
                    : _PlaceholderThumb(),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.my_location_rounded,
                          size: 14,
                          color: DealOneTokens.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Date & Time Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : const Color(0xFFF1F5F9),
              borderRadius: AppRadii.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(booking.bookingDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      booking.bookingTime?.isNotEmpty == true
                          ? booking.bookingTime!
                          : (isArabic ? '04:30 م' : '04:30 PM'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Consultant / Provider Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: DealOneTokens.cardSurfaceOf(context),
              borderRadius: AppRadii.md,
              border: Border.all(color: DealOneTokens.cardBorderOf(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: DealOneTokens.navy,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.real_estate_agent_outlined,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        isConfirmed
                            ? (isArabic
                                ? 'مستشار المعاينة العقارية'
                                : 'Real Estate Preview Advisor')
                            : (isArabic
                                ? 'الجهة المسوقة المعتمدة'
                                : 'Verified Listing Agency'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: DealOneTokens.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _CircleIconAction(
                  icon: Icons.phone_outlined,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'جاري تجهيز الاتصال بـ ${booking.providerName}'
                              : 'Preparing call to ${booking.providerName}',
                        ),
                      ),
                    );
                  },
                ),
                if (isConfirmed) ...[
                  const SizedBox(width: 6),
                  _CircleIconAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => context.push(RouteNames.conversations),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons Row
          if (isConfirmed)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DealOneTokens.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onOpenRoute,
                    icon: const Icon(Icons.near_me_outlined, size: 18),
                    label: Text(
                      isArabic ? 'الموقع والتفاصيل' : 'Location & Details',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFEFF4FF),
                      foregroundColor: DealOneTokens.textPrimaryOf(context),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onReschedule,
                    child: Text(
                      isArabic ? 'إعادة جدولة' : 'Reschedule',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFE0ECFF),
                      foregroundColor: DealOneTokens.navy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onOpenRoute,
                    icon: const Icon(Icons.sync_rounded, size: 17),
                    label: Text(
                      isArabic ? 'متابعة حالة الطلب' : 'Track Request',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : const Color(0xFFF8FAFC),
                      foregroundColor: DealOneTokens.dangerRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                        side: BorderSide(
                          color: DealOneTokens.cardBorderOf(context),
                        ),
                      ),
                    ),
                    onPressed: onCancel,
                    child: Text(
                      isArabic ? 'إلغاء الموعد' : 'Cancel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 78,
      color: AppColors.surfaceSecondaryOf(context),
      child: Icon(
        Icons.apartment_rounded,
        color: AppColors.textMutedOf(context),
        size: 30,
      ),
    );
  }
}

class _CircleIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.full,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : const Color(0xFFEFF4FF),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
    );
  }
}

class _FlexibilityPolicyCard extends StatelessWidget {
  final bool isArabic;

  const _FlexibilityPolicyCard({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5FF),
        borderRadius: AppRadii.lg,
        border: Border.all(color: DealOneTokens.cardBorderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : const Color(0xFFE2E8F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: DealOneTokens.navy,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'سياسة مرونة المعاينات' : 'Flexible Viewing Policy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'يمكنك إلغاء أو تغيير موعد المعاينة مجاناً بكل سهولة قبل ساعتين على الأقل من الوقت المحدد دون أي التزامات.'
                      : 'You can cancel or reschedule your viewing for free at least 2 hours before the scheduled time with no obligations.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
