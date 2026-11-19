import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../errors/error_presenter.dart';
import '../marketplace/section_home_models.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';

/// Formats an EGP price cleanly with thousands separators (e.g. `3,200,000 ج.م`).
String formatDealOnePrice(
  double price, {
  String currency = 'EGP',
  bool isArabic = true,
  String? unitSuffix,
}) {
  final formatted = price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final currLabel = currency == 'EGP' ? (isArabic ? 'ج.م' : 'EGP') : currency;
  if (unitSuffix != null && unitSuffix.isNotEmpty) {
    return '$formatted $currLabel / $unitSuffix';
  }
  return '$formatted $currLabel';
}

/// Displays authoritative live price if refreshed in [livePricesProvider],
/// otherwise shows cached price immediately without flicker.
class DealOneLivePriceText extends ConsumerWidget {
  final String listingId;
  final double cachedPrice;
  final String currency;
  final String? unitSuffix;
  final TextStyle? style;

  const DealOneLivePriceText({
    super.key,
    required this.listingId,
    required this.cachedPrice,
    this.currency = 'EGP',
    this.unitSuffix,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final snapshot = ref.watch(
      livePricesProvider.select((map) => map[listingId]),
    );
    final effectivePrice = snapshot?.price ?? cachedPrice;
    final effectiveCurrency = snapshot?.currency ?? currency;

    return Text(
      formatDealOnePrice(
        effectivePrice,
        currency: effectiveCurrency,
        isArabic: isArabic,
        unitSuffix: unitSuffix,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ??
          const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: DealOneDesignColors.amberPrice,
          ),
    );
  }
}

/// Offline / Stale-Cache banner shown gracefully at the top of any Home when offline.
class DealOneOfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const DealOneOfflineBanner({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DealOneDesignColors.amberPrice.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DealOneDesignColors.amberPrice.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 18,
            color: DealOneDesignColors.amberPrice,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isArabic
                  ? 'وضع عدم الاتصال — يتم عرض آخر البيانات المحفوظة'
                  : 'Offline mode — showing last saved data',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isArabic ? 'تحديث' : 'Retry',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: DealOneDesignColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title + optional leading icon + `عرض الكل` action link.
class DealOneSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? trailingIcon;

  const DealOneSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingIcon != null) ...[
                Icon(
                  trailingIcon,
                  size: 20,
                  color: isDark ? Colors.white : DealOneDesignColors.navy,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : DealOneDesignColors.navy,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two-tab segmented pill matching Home 3 (Appliances/Decor),
/// Home 5 (Building/Electrical), and Home 6 (Cars/Maintenance).
class DealOneSegmentedToggle extends StatelessWidget {
  final String firstLabel;
  final String secondLabel;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const DealOneSegmentedToggle({
    super.key,
    required this.firstLabel,
    required this.secondLabel,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          _buildSegment(context, 0, firstLabel, isDark),
          _buildSegment(context, 1, secondLabel, isDark),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    int index,
    String label,
    bool isDark,
  ) {
    final active = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: active ? DealOneDesignColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : DealOneDesignColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal `معاينات حية` (Live Previews) vertical story cards matching Home 2 & Home 6.
class DealOneLivePreviewsStrip extends StatelessWidget {
  final List<LivePreviewItem> items;

  const DealOneLivePreviewsStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: 224,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => context.push('/listings/${item.listingId}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 152,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        cacheWidth: 420,
                        errorBuilder: (_, _, _) => Container(
                          color: DealOneDesignColors.navy,
                        ),
                      )
                    else
                      Container(color: DealOneDesignColors.navy),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.38, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.white,
                                child: Text(
                                  item.sellerName.isNotEmpty
                                      ? item.sellerName.characters.first
                                      : 'D',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: DealOneDesignColors.navy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.sellerName.isNotEmpty
                                      ? item.sellerName
                                      : (isArabic ? 'بائع موثق' : 'Verified'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isArabic
                                      ? '${item.mediaCount} صور'
                                      : '${item.mediaCount} photos',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatDealOnePrice(
                              item.price,
                              currency: item.currency,
                              isArabic: isArabic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DealOneSectionSkeleton extends StatelessWidget {
  final double height;

  const DealOneSectionSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class DealOneSectionEmptyCard extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DealOneSectionEmptyCard({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: AppColors.textMutedOf(context),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textMutedOf(context),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class DealOneSectionErrorCard extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const DealOneSectionErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final presented = ErrorPresenter.present(error, isArabic: isArabic);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorOf(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            presented.kind == FeatureErrorKind.offline
                ? Icons.wifi_off_rounded
                : Icons.error_outline_rounded,
            color: AppColors.errorOf(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presented.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  presented.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (presented.canRetry)
            TextButton(
              onPressed: onRetry,
              child: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
