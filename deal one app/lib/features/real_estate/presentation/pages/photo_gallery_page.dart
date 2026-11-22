import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/favorites/presentation/providers/favorites_providers.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/real_estate/presentation/widgets/gallery_hero_viewer.dart';
import 'package:market_space/features/real_estate/presentation/widgets/gallery_thumbnail_grid.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

class PhotoGalleryArgs {
  final ListingItem? listing;
  final int initialIndex;

  const PhotoGalleryArgs({this.listing, this.initialIndex = 0});
}

/// Property Photo Gallery Screen matching `Photo Gallery.png`.
/// Supports swipeable hero viewer, pinch-to-zoom fullscreen lightbox, and 2-column thumbnail grid.
class PhotoGalleryPage extends ConsumerStatefulWidget {
  final String listingId;
  final ListingItem? initialListing;
  final int initialIndex;

  const PhotoGalleryPage({
    super.key,
    required this.listingId,
    this.initialListing,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreenZoom(ListingItem item, List<ListingMedia> images) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.94),
        pageBuilder: (_, _, _) => _FullscreenPhotoLightbox(
          listingId: item.id,
          images: images,
          initialIndex: _currentIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;

    final AsyncValue<ListingItem> listingAsync = widget.initialListing != null
        ? AsyncValue.data(widget.initialListing!)
        : ref.watch(listingDetailsFamily(widget.listingId));

    return listingAsync.when(
      loading: () => Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: isArabic ? 'جميع صور العقار' : 'Property Photos',
              ),
              Expanded(
                child: DealOneErrorStateView(
                  error: err,
                  onRetry: () =>
                      ref.invalidate(listingDetailsFamily(widget.listingId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (item) {
        final images = item.media
            .where((m) => m.mediaType.toLowerCase() != 'video')
            .toList();
        final favIds = ref.watch(favoriteIdsProvider);
        final isFav = favIds.contains(item.id);
        final isRent = item.listingKind.toLowerCase() == 'rent' ||
            item.categorySlug.contains('rent');

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
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DealOneTokens.softTileBgOf(context),
                      borderRadius: AppRadii.md,
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 21,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDealOnePrice(
                            item.price,
                            currency: item.currency,
                            isArabic: isArabic,
                            unitSuffix:
                                isRent ? (isArabic ? 'شهرياً' : 'mo') : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: DealOneTokens.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DealOneTokens.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: () {
                      if (images.isNotEmpty) {
                        _openFullscreenZoom(item, images);
                      }
                    },
                    icon: const Icon(Icons.zoom_in_rounded, size: 18),
                    label: Text(
                      isArabic ? 'عرض بدقة كاملة' : 'Full View',
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                DealOneSubPageHeader(
                  title: isArabic ? 'جميع صور العقار' : 'Property Photos',
                  onBack: () {
                    if (context.canPop()) context.pop();
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isArabic ? 'مشاركة' : 'Share',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '${item.title} — ${item.id}'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'تم نسخ رابط العقار'
                                    : 'Property link copied',
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.share_outlined,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                      IconButton(
                        tooltip: isArabic ? 'حفظ' : 'Save',
                        onPressed: () => ref
                            .read(favoritesControllerProvider.notifier)
                            .toggleFavorite(item.id),
                        icon: Icon(
                          isFav
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFav
                              ? DealOneTokens.amber
                              : DealOneTokens.textPrimaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: images.isEmpty
                      ? DealOneEmptyStateView(
                          icon: Icons.photo_library_outlined,
                          title: isArabic
                              ? 'لا توجد صور متاحة'
                              : 'No photos available',
                          description: isArabic
                              ? 'لم يقم المعلن بإرفاق صور لهذا العقار بعد.'
                              : 'No photos have been attached to this property yet.',
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            AppSpacing.sm,
                            hPad,
                            AppSpacing.xxl,
                          ),
                          children: [
                            GalleryHeroViewer(
                              listingId: item.id,
                              images: images,
                              currentIndex:
                                  _currentIndex.clamp(0, images.length - 1),
                              pageController: _pageController,
                              onPageChanged: (idx) =>
                                  setState(() => _currentIndex = idx),
                              onOpenFullscreen: () =>
                                  _openFullscreenZoom(item, images),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Section Header matching PNG
                            Row(
                              children: [
                                Text(
                                  isArabic ? 'معرض الصور' : 'Photo Gallery',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneTokens.textPrimaryOf(context),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DealOneTokens.softTileBgOf(context),
                                    borderRadius: AppRadii.full,
                                  ),
                                  child: Text(
                                    isArabic
                                        ? '${images.length} لقطات'
                                        : '${images.length} photos',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          DealOneTokens.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    isArabic
                                        ? 'انقر لعرض الصورة بدقة كاملة'
                                        : 'Tap for full resolution',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: DealOneTokens.textSecondaryOf(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            GalleryThumbnailGrid(
                              images: images,
                              currentIndex:
                                  _currentIndex.clamp(0, images.length - 1),
                              onSelectImage: (idx) {
                                if (idx == _currentIndex) {
                                  _openFullscreenZoom(item, images);
                                } else {
                                  setState(() => _currentIndex = idx);
                                  _pageController.animateToPage(
                                    idx,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullscreenPhotoLightbox extends StatefulWidget {
  final String listingId;
  final List<ListingMedia> images;
  final int initialIndex;

  const _FullscreenPhotoLightbox({
    required this.listingId,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenPhotoLightbox> createState() =>
      _FullscreenPhotoLightboxState();
}

class _FullscreenPhotoLightboxState extends State<_FullscreenPhotoLightbox> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, idx) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Hero(
                      tag: 'listing-photo-${widget.listingId}-$idx',
                      child: AppNetworkImage(
                        imageUrl: widget.images[idx].publicUrl,
                        fit: BoxFit.contain,
                        enableRetry: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            PositionedDirectional(
              top: AppSpacing.md,
              start: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.md,
              end: AppSpacing.md,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
