import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_center/application/providers/seller_center_providers.dart';
import 'package:market_space/features/seller_center/domain/entities/seller_center_entities.dart';
import 'package:market_space/shared/widgets/app_loading_indicator.dart';

class SellerAdsTab extends ConsumerWidget {
  const SellerAdsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final selectedStatus = ref.watch(sellerAdsStatusFilterProvider);
    final listingsAsync = ref.watch(sellerCenterListingsProvider);

    final statuses = [
      ('all', isArabic ? 'الكل' : 'All'),
      ('published', isArabic ? 'نشط' : 'Published'),
      ('hidden', isArabic ? 'متوقف مؤقتاً' : 'Paused'),
      ('pending', isArabic ? 'قيد المراجعة' : 'Pending'),
      ('archived', isArabic ? 'مؤرشف' : 'Archived'),
    ];

    return Column(
      children: [
        // Search + Create Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'ابحث في إعلاناتك...'
                        : 'Search your advertisements...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.md,
                      borderSide: BorderSide(
                        color: DealOneTokens.cardBorderOf(context),
                      ),
                    ),
                  ),
                  onChanged: (val) =>
                      ref.read(sellerAdsSearchProvider.notifier).state = val,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.push(RouteNames.createListing),
                icon: const Icon(Icons.add_rounded),
                tooltip: isArabic ? 'إضافة إعلان' : 'Create Ad',
              ),
            ],
          ),
        ),

        // Status Filter Chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, idx) {
              final (value, label) = statuses[idx];
              final active = selectedStatus == value;
              return ChoiceChip(
                label: Text(label),
                selected: active,
                onSelected: (_) => ref
                    .read(sellerAdsStatusFilterProvider.notifier)
                    .state = value,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Listings List
        Expanded(
          child: RefreshIndicator(
            color: DealOneTokens.navy,
            onRefresh: () async =>
                ref.invalidate(sellerCenterListingsProvider),
            child: listingsAsync.when(
              loading: () => const Center(child: DealOneDotLoader(dotSize: 9)),
              error: (err, _) => DealOneErrorStateView(
                error: err,
                onRetry: () => ref.invalidate(sellerCenterListingsProvider),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return DealOneEmptyStateView(
                    icon: Icons.campaign_outlined,
                    title: isArabic ? 'لا توجد إعلانات' : 'No Advertisements',
                    description: isArabic
                        ? 'أضف إعلانك الأول للبدء في تلقي استفسارات العملاء.'
                        : 'Create your first advertisement to start receiving inquiries.',
                    actionLabel: isArabic ? 'إضافة إعلان' : 'Create Ad',
                    actionIcon: Icons.add_rounded,
                    onAction: () => context.push(RouteNames.createListing),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: result.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ad = result.items[index];
                    return _SellerAdCard(
                      ad: ad,
                      isArabic: isArabic,
                      onAction: (action) =>
                          _handleAdAction(context, ref, ad, action, isArabic),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAdAction(
    BuildContext context,
    WidgetRef ref,
    SellerListingItemEntity ad,
    String action,
    bool isArabic,
  ) async {
    final repo = ref.read(sellerCenterRepositoryProvider);
    try {
      if (action == 'view') {
        context.push('/listings/${ad.id}');
        return;
      }
      if (action == 'pause') {
        await repo.updateListingPublicationStatus(ad.id, 'hidden');
      } else if (action == 'resume') {
        await repo.updateListingPublicationStatus(ad.id, 'published');
      } else if (action == 'archive') {
        await repo.updateListingPublicationStatus(ad.id, 'archived');
      } else if (action == 'sold') {
        await repo.updateListingAvailability(
          ad.id,
          ad.listingKind == 'rent' ? 'rented' : 'sold',
        );
      } else if (action == 'delete') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isArabic ? 'حذف الإعلان' : 'Delete Advertisement'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من حذف "${ad.title}"؟'
                  : 'Are you sure you want to delete "${ad.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.dangerRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(isArabic ? 'حذف' : 'Delete'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await repo.deleteListing(ad.id);
      }

      ref.invalidate(sellerCenterListingsProvider);
      ref.invalidate(sellerDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم تحديث الإعلان بنجاح' : 'Advertisement updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

class _SellerAdCard extends StatelessWidget {
  final SellerListingItemEntity ad;
  final bool isArabic;
  final ValueChanged<String> onAction;

  const _SellerAdCard({
    required this.ad,
    required this.isArabic,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = ad.publicationStatus == 'hidden';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: DealOneTokens.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onAction,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Text(isArabic ? 'عرض التفاصيل' : 'View Details'),
                  ),
                  PopupMenuItem(
                    value: isPaused ? 'resume' : 'pause',
                    child: Text(
                      isPaused
                          ? (isArabic ? 'استئناف النشر' : 'Resume')
                          : (isArabic ? 'إيقاف مؤقت' : 'Pause'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sold',
                    child: Text(
                      ad.listingKind == 'rent'
                          ? (isArabic ? 'تحديد كمؤجر' : 'Mark Rented')
                          : (isArabic ? 'تحديد كمباع' : 'Mark Sold'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(isArabic ? 'أرشفة' : 'Archive'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      isArabic ? 'حذف' : 'Delete',
                      style: const TextStyle(color: DealOneTokens.dangerRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusTag(label: ad.publicationStatus.toUpperCase()),
              _StatusTag(label: ad.availabilityStatus.toUpperCase()),
              Text(
                '${ad.price.toStringAsFixed(0)} ${ad.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 15,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text('${ad.viewsCount}', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(width: 14),
              Icon(
                Icons.favorite_border_rounded,
                size: 15,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                '${ad.favoritesCount}',
                style: const TextStyle(fontSize: 12.5),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 15,
                color: DealOneTokens.textSecondaryOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                '${ad.inquiriesCount}',
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  const _StatusTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DealOneTokens.navy.withValues(alpha: 0.1),
        borderRadius: AppRadii.full,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
    );
  }
}
