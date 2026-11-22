import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/real_estate/domain/entities/reel_item_entity.dart';

/// Full-screen Reels overlay UI matching `Real Estate Reels Viewer.png`:
/// Top story progress bars + "معاينة حية" badge + mute/close controls,
/// Vertical action rail (Favorite, Share, Chat, Map),
/// Bottom seller + title + location + amber price pill + Call & Full Details CTA row.
class ReelOverlayControls extends StatelessWidget {
  final ReelItemEntity item;
  final int totalSegments;
  final int activeIndex;
  final double progress;
  final bool isPlaying;
  final bool isMuted;
  final bool isFavorite;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenMap;
  final VoidCallback onCallSeller;
  final VoidCallback onOpenDetails;

  const ReelOverlayControls({
    super.key,
    required this.item,
    required this.totalSegments,
    required this.activeIndex,
    required this.progress,
    required this.isPlaying,
    required this.isMuted,
    required this.isFavorite,
    required this.onClose,
    required this.onToggleMute,
    required this.onTogglePlay,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onOpenChat,
    required this.onOpenMap,
    required this.onCallSeller,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final rooms = item.attributes['rooms'];
    final baths = item.attributes['baths'];
    final finishing = item.attributes['finishing']?.toString();
    final segmentCount = totalSegments.clamp(1, 6);
    final activeSegment = activeIndex % segmentCount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            // 1. Top Segmented Progress Bar
            Row(
              children: List.generate(segmentCount, (i) {
                final fill = i < activeSegment
                    ? 1.0
                    : (i == activeSegment ? progress.clamp(0.0, 1.0) : 0.0);
                return Expanded(
                  child: Container(
                    height: 3.5,
                    margin: EdgeInsetsDirectional.only(
                      end: i == segmentCount - 1 ? 0 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: AppRadii.full,
                    ),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fill,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadii.full,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Top Controls Row: Close, Live Preview Pill, Mute
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ReelCircleIcon(icon: Icons.close_rounded, onTap: onClose),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DealOneTokens.navy.withValues(alpha: 0.78),
                    borderRadius: AppRadii.full,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DealOneTokens.amberWarm,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic ? 'معاينة حية • HD' : 'Live Preview • HD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReelCircleIcon(
                      icon: isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: onToggleMute,
                    ),
                    const SizedBox(width: 8),
                    _ReelCircleIcon(
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: onTogglePlay,
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // 3. Middle-Bottom Row: Property Info (Start) + Vertical Action Rail (End)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seller Row
                      Row(
                        children: [
                          DealOneAvatar(
                            imageUrl: item.sellerAvatarUrl,
                            fallbackText: item.sellerName,
                            size: 40,
                            isVerified: true,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  item.locationDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Property Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location Line
                      if (item.locationDisplay.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: DealOneTokens.amberWarm,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.locationDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.sm),

                      // Amber Price Pill matching PNG
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: DealOneTokens.amber,
                          borderRadius: AppRadii.md,
                        ),
                        child: Text(
                          formatDealOnePrice(
                            item.price,
                            currency: item.currency,
                            isArabic: isArabic,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      // Compact Specs Pill
                      if (rooms != null || baths != null || finishing != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: AppRadii.full,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (rooms != null)
                                Text(
                                  isArabic ? '$rooms غرف' : '$rooms Beds',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (baths != null)
                                Text(
                                  isArabic ? '• $baths حمام' : '• $baths Baths',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (finishing != null && finishing.isNotEmpty)
                                Text(
                                  '• $finishing',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Vertical Action Rail
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReelRailAction(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite ? DealOneTokens.dangerRed : Colors.white,
                      label: '${item.favoritesCount}',
                      onTap: onToggleFavorite,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ReelRailAction(
                      icon: Icons.share_outlined,
                      label: isArabic ? 'مشاركة' : 'Share',
                      onTap: onShare,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ReelRailAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: isArabic ? 'محادثة' : 'Chat',
                      onTap: onOpenChat,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ReelRailAction(
                      icon: Icons.map_outlined,
                      label: isArabic ? 'الخريطة' : 'Map',
                      onTap: onOpenMap,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // 4. Bottom CTA Row (Full Details + Amber Call Button)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('reel_open_details_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DealOneTokens.navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 50),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.md,
                      ),
                    ),
                    onPressed: onOpenDetails,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      isArabic
                          ? 'عرض تفاصيل العقار كاملة'
                          : 'View Full Property Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Material(
                  color: DealOneTokens.amber,
                  borderRadius: AppRadii.md,
                  child: InkWell(
                    onTap: onCallSeller,
                    borderRadius: AppRadii.md,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ReelCircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DealOneTokens.navy.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _ReelRailAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelRailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
