import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/errors/error_presenter.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/listings/presentation/widgets/deal_one_listing_card.dart';
import 'package:market_space/features/moderation/data/dto/report_dto.dart';
import 'package:market_space/features/moderation/data/repositories/reports_repository_impl.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(listingDetailsFamily(listingId));

    return detailAsync.when(
      data: (item) {
        // Persist in last-viewed cache without blocking UI
        ref.read(hybridCacheManagerProvider).recordViewedListing(
              id: item.id,
              title: item.title,
              price: item.price,
              currency: item.currency,
              imageUrl: item.primaryImageUrl,
              categorySlug: item.categorySlug,
            );
        return _DetailView(item: item);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) {
        final isArabic = Directionality.of(context) == TextDirection.rtl;
        final presented = ErrorPresenter.present(err, isArabic: isArabic);
        return Scaffold(
          appBar: AppBar(
            title: Text(isArabic ? 'تفاصيل الإعلان' : 'Listing Details'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    presented.kind == FeatureErrorKind.offline
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline,
                    size: 48,
                    color: AppColors.errorOf(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    presented.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    presented.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMutedOf(context)),
                  ),
                  if (presented.canRetry) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(listingDetailsFamily(listingId)),
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailView extends ConsumerStatefulWidget {
  final ListingItem item;

  const _DetailView({required this.item});

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  int _currentImageIndex = 0;

  ({String label, IconData icon}) _specMeta(String key, bool isArabic) {
    final k = key.toLowerCase();
    return switch (k) {
      'rooms' => (
          label: isArabic ? 'الغرف' : 'Rooms',
          icon: Icons.bed_outlined,
        ),
      'baths' => (
          label: isArabic ? 'الحمامات' : 'Bathrooms',
          icon: Icons.bathtub_outlined,
        ),
      'area_sqm' => (
          label: isArabic ? 'المساحة (م²)' : 'Area (sqm)',
          icon: Icons.square_foot_rounded,
        ),
      'land_area_sqm' => (
          label: isArabic ? 'مساحة الأرض (م²)' : 'Land Area (sqm)',
          icon: Icons.landscape_outlined,
        ),
      'floor' => (
          label: isArabic ? 'الدور' : 'Floor',
          icon: Icons.stairs_outlined,
        ),
      'finishing' => (
          label: isArabic ? 'التشطيب' : 'Finishing',
          icon: Icons.format_paint_outlined,
        ),
      'furnished' => (
          label: isArabic ? 'مفروش' : 'Furnished',
          icon: Icons.chair_outlined,
        ),
      'rental_period' => (
          label: isArabic ? 'مدة الإيجار' : 'Rental Period',
          icon: Icons.calendar_month_outlined,
        ),
      'has_pool' => (
          label: isArabic ? 'حمام سباحة' : 'Swimming Pool',
          icon: Icons.pool_rounded,
        ),
      'unit_type' => (
          label: isArabic ? 'نوع الوحدة' : 'Unit Type',
          icon: Icons.business_outlined,
        ),
      'land_type' => (
          label: isArabic ? 'نوع الأرض' : 'Land Type',
          icon: Icons.terrain_outlined,
        ),
      'brand' || 'make' => (
          label: isArabic ? 'الماركة' : 'Brand',
          icon: Icons.branding_watermark_outlined,
        ),
      'model' => (
          label: isArabic ? 'الموديل' : 'Model',
          icon: Icons.directions_car_outlined,
        ),
      'year' => (
          label: isArabic ? 'سنة الصنع' : 'Year',
          icon: Icons.date_range_outlined,
        ),
      'mileage' || 'kilometers' => (
          label: isArabic ? 'الكيلومترات' : 'Mileage',
          icon: Icons.speed_rounded,
        ),
      'transmission' => (
          label: isArabic ? 'ناقل الحركة' : 'Transmission',
          icon: Icons.settings_outlined,
        ),
      'fuel_type' => (
          label: isArabic ? 'الوقود' : 'Fuel Type',
          icon: Icons.local_gas_station_outlined,
        ),
      'condition' => (
          label: isArabic ? 'الحالة' : 'Condition',
          icon: Icons.verified_outlined,
        ),
      'warranty' => (
          label: isArabic ? 'الضمان' : 'Warranty',
          icon: Icons.shield_outlined,
        ),
      'size' => (
          label: isArabic ? 'المقاس' : 'Size',
          icon: Icons.straighten_rounded,
        ),
      'color' => (
          label: isArabic ? 'اللون' : 'Color',
          icon: Icons.palette_outlined,
        ),
      'material' => (
          label: isArabic ? 'الخامة' : 'Material',
          icon: Icons.texture_rounded,
        ),
      'service_type' => (
          label: isArabic ? 'نوع الخدمة' : 'Service Type',
          icon: Icons.handyman_outlined,
        ),
      _ => (
          label: key.replaceAll('_', ' '),
          icon: Icons.info_outline_rounded,
        ),
    };
  }

  String _formatSpecValue(dynamic val, bool isArabic) {
    if (val is bool) {
      return val ? (isArabic ? 'نعم' : 'Yes') : (isArabic ? 'لا' : 'No');
    }
    return val.toString();
  }

  String _sellerTypeLabel(String type, bool isArabic) {
    return switch (type.toLowerCase()) {
      'company' => isArabic ? 'شركة معتمدة' : 'Company',
      'store' => isArabic ? 'متجر' : 'Store',
      'factory' => isArabic ? 'مصنع' : 'Factory',
      'office' => isArabic ? 'مكتب هندسي / عقاري' : 'Office',
      _ => isArabic ? 'حساب أفراد' : 'Individual',
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final revealState = ref.watch(contactRevealProvider(item.id));
    ref.watch(favoritesProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final isFav = favoritesNotifier.isFavorited(item.id);
    final categoryLabel = isArabic
        ? (item.categoryNameAr.isNotEmpty
            ? item.categoryNameAr
            : item.categoryNameEn)
        : (item.categoryNameEn.isNotEmpty
            ? item.categoryNameEn
            : item.categoryNameAr);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? AppColors.errorOf(context) : null,
            ),
            onPressed: () => favoritesNotifier.toggleFavorite(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: isArabic ? 'إبلاغ عن الإعلان' : 'Report listing',
            onPressed: () => _showReportDialog(context, ref, item.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Gallery with counter & dots
            if (item.media.isNotEmpty)
              SizedBox(
                height: 290,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: item.media.length,
                      onPageChanged: (idx) =>
                          setState(() => _currentImageIndex = idx),
                      itemBuilder: (context, index) {
                        final media = item.media[index];
                        return Image.network(
                          media.publicUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: AppColors.surfaceSecondaryOf(context),
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 50,
                              color: AppColors.textMutedOf(context),
                            ),
                          ),
                        );
                      },
                    ),
                    PositionedDirectional(
                      bottom: 12,
                      end: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${item.media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (item.isFeatured)
                      PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.priceAmber,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            isArabic ? 'إعلان مميز' : 'Featured',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                color: AppColors.surfaceSecondaryOf(context),
                child: Center(
                  child: Icon(
                    Icons.photo_outlined,
                    size: 60,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),

            // Main Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (categoryLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: DealOneDesignColors.navy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            categoryLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondaryOf(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.condition.toUpperCase() == 'NEW'
                              ? (isArabic ? 'جديد' : 'New')
                              : (isArabic ? 'مستعمل / متاح' : 'Used / Available'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatEgpPrice(item.price, isArabic: isArabic),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DealOneDesignColors.priceAmber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.localizedLocation(isArabic ? 'ar' : 'en'),
                          style: TextStyle(color: AppColors.textMutedOf(context)),
                        ),
                      ),
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.viewsCount}',
                        style: TextStyle(color: AppColors.textMutedOf(context)),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Dynamic Category-Specific Specifications
                  if (item.attributes.isNotEmpty) ...[
                    Text(
                      isArabic ? 'المواصفات والخصائص' : 'Specifications',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.attributes.entries
                          .where((e) => e.value != null && e.value.toString().isNotEmpty)
                          .map((entry) {
                        final meta = _specMeta(entry.key, isArabic);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondaryOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                meta.icon,
                                size: 16,
                                color: DealOneDesignColors.navy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${meta.label}: ${_formatSpecValue(entry.value, isArabic)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 28),
                  ],

                  // Description
                  Text(
                    isArabic ? 'الوصف' : 'Description',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14.5, height: 1.6),
                  ),
                  const Divider(height: 28),

                  // Seller Information Card
                  Text(
                    isArabic ? 'معلومات البائع' : 'Seller Information',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondaryOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: DealOneDesignColors.navy,
                          child: Text(
                            item.sellerName.isNotEmpty
                                ? item.sellerName.characters.first
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.sellerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (item.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _sellerTypeLabel(item.sellerType, isArabic),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMutedOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            border: Border(top: BorderSide(color: AppColors.borderOf(context))),
          ),
          child: revealState.when(
            data: (contactResult) {
              if (contactResult != null) {
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successOf(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.phone),
                        label: Text(
                          contactResult.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                    if (contactResult.whatsappUrl != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.chat),
                        onPressed: () {},
                      ),
                    ],
                  ],
                );
              }

              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneDesignColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: Text(
                  isArabic
                      ? 'إظهار رقم الهاتف والتواصل'
                      : 'Reveal Phone & Contact Seller',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  ref
                      .read(contactRevealProvider(item.id).notifier)
                      .reveal(item.id);
                },
              );
            },
            loading: () => const Center(
              heightFactor: 1.5,
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (err, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic
                        ? 'تعذر إظهار الرقم: $err'
                        : 'Could not reveal contact: $err',
                    style: TextStyle(
                      color: AppColors.errorOf(context),
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(contactRevealProvider(item.id).notifier)
                      .reveal(item.id),
                  child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    WidgetRef ref,
    String listingId,
  ) {
    String selectedReason = 'scam';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إبلاغ عن هذا الإعلان'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceOf(context),
                    items: const [
                      DropdownMenuItem(
                        value: 'scam',
                        child: Text('احتيال أو إعلان مضلل'),
                      ),
                      DropdownMenuItem(
                        value: 'inappropriate',
                        child: Text('محتوى غير لائق'),
                      ),
                      DropdownMenuItem(
                        value: 'false_info',
                        child: Text('معلومات غير صحيحة'),
                      ),
                      DropdownMenuItem(
                        value: 'duplicate',
                        child: Text('إعلان مكرر'),
                      ),
                      DropdownMenuItem(
                        value: 'prohibited',
                        child: Text('سلعة محظورة'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('أسباب أخرى'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'ملاحظات إضافية (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final apiClient = ref.read(apiClientProvider);
                    final repo = ReportsRepositoryImpl(apiClient: apiClient);
                    await repo.fileReport(
                      CreateReportDto(
                        listingId: listingId,
                        reason: selectedReason,
                        notes: notesController.text.trim().isNotEmpty
                            ? notesController.text.trim()
                            : null,
                      ),
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم استلام البلاغ وسيقوم فريق المراجعة بفحصه',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('إرسال البلاغ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
