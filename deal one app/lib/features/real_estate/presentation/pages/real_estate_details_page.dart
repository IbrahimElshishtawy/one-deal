import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/errors/app_exception.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/bookings/booking_request_sheet.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/conversations/presentation/providers/conversations_providers.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/real_estate/presentation/pages/photo_gallery_page.dart';
import 'package:market_space/features/real_estate/presentation/widgets/real_estate_description_card.dart';
import 'package:market_space/features/real_estate/presentation/widgets/real_estate_details_hero.dart';
import 'package:market_space/features/real_estate/presentation/widgets/real_estate_location_preview.dart';
import 'package:market_space/features/real_estate/presentation/widgets/real_estate_specs_grid.dart';

/// Real Estate Details Screen matching `Real Estate Details.png`.
/// Connected to `GET /listings/:id`, `POST /conversations`, `POST /listings/:id/contact`, and Favorites.
class RealEstateDetailsPage extends ConsumerWidget {
  final String listingId;
  final ListingItem? preloadedItem;

  const RealEstateDetailsPage({
    super.key,
    required this.listingId,
    this.preloadedItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final detailAsync = preloadedItem != null
        ? AsyncValue.data(preloadedItem!)
        : ref.watch(listingDetailsFamily(listingId));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (err, _) {
        final isNotFound = err is NotFoundException ||
            err.toString().toLowerCase().contains('not found') ||
            err.toString().contains('404');
        return Scaffold(
          backgroundColor: DealOneTokens.pageBgOf(context),
          body: SafeArea(
            child: Column(
              children: [
                DealOneSubPageHeader(
                  title: isArabic ? 'تفاصيل العقار' : 'Property Details',
                ),
                Expanded(
                  child: isNotFound
                      ? DealOneEmptyStateView(
                          icon: Icons.home_work_outlined,
                          title: isArabic
                              ? 'هذا العقار غير متاح حالياً'
                              : 'Property Unavailable',
                          description: isArabic
                              ? 'ربما تم بيع العقار أو حذفه من قبل المعلن.'
                              : 'This property may have been removed or is no longer published.',
                          actionLabel: isArabic
                              ? 'تصفح عقارات أخرى'
                              : 'Browse Other Properties',
                          actionIcon: Icons.explore_outlined,
                          onAction: () => context.go(RouteNames.realEstate),
                        )
                      : DealOneErrorStateView(
                          error: err,
                          onRetry: () =>
                              ref.invalidate(listingDetailsFamily(listingId)),
                        ),
                ),
              ],
            ),
          ),
        );
      },
      data: (item) => _RealEstateDetailsBody(item: item),
    );
  }
}

class _RealEstateDetailsBody extends ConsumerWidget {
  final ListingItem item;

  const _RealEstateDetailsBody({required this.item});

  Future<void> _startConversation(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      context.push(RouteNames.login);
      return;
    }
    try {
      final conv = await ref
          .read(conversationsRepositoryProvider)
          .startOrGetConversation(item.id, currentUserId: session.userId);
      if (context.mounted) {
        context.push('/conversations/${conv.id}', extra: conv);
      }
    } catch (e) {
      // Fallback: reveal contact phone if user tries to chat on own listing or chat unavailable
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final l10n = AppLocalization.of(context);
    final favIds = ref.watch(favoriteIdsProvider);
    final isFav = favIds.contains(item.id);
    final isRent = item.listingKind.toLowerCase() == 'rent' ||
        item.categorySlug.contains('rent');
    final shortCode = item.id.length > 6
        ? item.id.substring(0, 6).toUpperCase()
        : item.id.toUpperCase();
    final categoryLabel = isArabic
        ? (item.categoryNameAr.isNotEmpty
            ? item.categoryNameAr
            : item.categoryNameEn)
        : (item.categoryNameEn.isNotEmpty
            ? item.categoryNameEn
            : item.categoryNameAr);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: DealOneTokens.cardSurfaceOf(context),
            border: Border(
              top: BorderSide(color: DealOneTokens.cardBorderOf(context)),
            ),
            boxShadow: DealOneTokens.cardShadow(context),
          ),
          child: Row(
            children: [
              DealOneAvatar(
                imageUrl: item.sellerAvatarUrl,
                fallbackText: item.sellerName,
                size: 46,
                isVerified: item.isVerified,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.sellerName.isNotEmpty
                                ? item.sellerName
                                : (isArabic ? 'المعلن' : 'Advertiser'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: DealOneTokens.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        if (item.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: DealOneTokens.navy,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.sellerType == 'individual'
                          ? (isArabic ? 'مالك مباشر' : 'Direct Owner')
                          : (isArabic ? 'شركة / مكتب معتمد' : 'Verified Agency'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: DealOneTokens.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                key: const Key('real_estate_chat_seller_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                ),
                onPressed: () => _startConversation(context, ref),
                icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                label: Text(
                  isArabic ? 'تحدث مع المعلن' : 'Chat Seller',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RealEstateDetailsHero(
              item: item,
              isFavorite: isFav,
              onBack: () {
                if (context.canPop()) context.pop();
              },
              onToggleFavorite: () => ref
                  .read(favoritesControllerProvider.notifier)
                  .toggleFavorite(item.id),
              onShare: () {
                Clipboard.setData(
                  ClipboardData(text: '${item.title} — #DL-$shortCode'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'تم نسخ بيانات العقار للمشاركة'
                          : 'Property link copied to share',
                    ),
                  ),
                );
              },
              onOpenGallery: (idx) => context.push(
                '/real-estate/gallery/${item.id}',
                extra: PhotoGalleryArgs(listing: item, initialIndex: idx),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              AppSpacing.lg,
              hPad,
              AppSpacing.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Verified + Listing ID Row
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (categoryLabel.isNotEmpty)
                            _MetaTagPill(label: categoryLabel),
                          if (item.isVerified)
                            _MetaTagPill(
                              label: isArabic ? 'معاينة مؤكدة' : 'Verified',
                              icon: Icons.verified_outlined,
                            ),
                          Text(
                            isArabic
                                ? 'رقم الإعلان: #DL-$shortCode'
                                : 'Listing #DL-$shortCode',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: context.isSmallPhone ? 19 : 22,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Location Line
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: DealOneTokens.amber,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.localizedLocation(isArabic ? 'ar' : 'en'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: DealOneTokens.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Highlighted Price Card matching PNG
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: DealOneTokens.softTileBgOf(context),
                          borderRadius: AppRadii.lg,
                          border: Border.all(
                            color: DealOneTokens.cardBorderOf(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRent
                                        ? (isArabic
                                            ? 'الإيجار الشهري'
                                            : 'Monthly Rent')
                                        : (isArabic
                                            ? 'السعر الإجمالي'
                                            : 'Total Price'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: DealOneTokens.textSecondaryOf(
                                        context,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DealOneLivePriceText(
                                    listingId: item.id,
                                    cachedPrice: item.price,
                                    currency: item.currency,
                                    unitSuffix: isRent
                                        ? (isArabic ? 'شهرياً' : 'mo')
                                        : null,
                                    style: TextStyle(
                                      fontSize: context.isSmallPhone ? 20 : 23,
                                      fontWeight: FontWeight.w900,
                                      color: DealOneTokens.textPrimaryOf(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: DealOneTokens.amberTintOf(context),
                                  borderRadius: AppRadii.full,
                                  border: Border.all(
                                    color: DealOneTokens.amberBorder,
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'عرض مميز' : 'Featured',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.amber,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Key Specifications Grid
                      RealEstateSpecsGrid(attributes: item.attributes),
                      const SizedBox(height: AppSpacing.xl),

                      // Detailed Description Card
                      RealEstateDescriptionCard(description: item.description),
                      const SizedBox(height: AppSpacing.xl),

                      // Map Location Preview
                      RealEstateLocationPreview(
                        item: item,
                        onOpenMap: () => context.push(
                          RouteNames.realEstateMap,
                          extra: item,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Request Viewing Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ActivityActionButton(
                          label: l10n.actionRequestViewing,
                          icon: Icons.event_available_outlined,
                          isOutlined: true,
                          onPressed: () => BookingRequestSheet.show(
                            context,
                            listingId: item.id,
                            title: item.title,
                            providerName: item.sellerName,
                            category: BookingCategory.realEstate,
                            defaultType: BookingType.propertyViewing,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaTagPill extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _MetaTagPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DealOneTokens.softTileBgOf(context),
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
