import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Pinned Telegram-style context banner showing the marketplace listing
/// associated with the current chat thread.
class ChatListingContextBanner extends StatelessWidget {
  final ConversationListingPreview listing;
  final ChatColorTheme colorTheme;
  final VoidCallback onOpenListing;
  final VoidCallback? onDismiss;

  const ChatListingContextBanner({
    super.key,
    required this.listing,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onOpenListing,
    this.onDismiss,
  });

  String _formatPrice(double price, bool isArabic) {
    if (price <= 0) return isArabic ? 'السعر عند التواصل' : 'Price on request';
    final intVal = price.round();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return isArabic ? '$formatted ج.م' : 'EGP $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);
    final hasImage =
        listing.imageUrl != null && listing.imageUrl!.trim().isNotEmpty;

    return Material(
      key: const Key('chat_listing_context_banner'),
      color: DealOneTokens.cardSurfaceOf(context),
      child: InkWell(
        onTap: onOpenListing,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: DealOneTokens.cardBorderOf(context)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadii.full,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.sm,
                child: Container(
                  width: 40,
                  height: 40,
                  color: DealOneTokens.softTileBgOf(context),
                  child: hasImage
                      ? Image.network(
                          listing.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.home_work_outlined,
                            size: 20,
                            color: accent,
                          ),
                        )
                      : Icon(
                          Icons.home_work_outlined,
                          size: 20,
                          color: accent,
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(listing.price, isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.amber,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  isArabic ? 'عرض الإعلان' : 'View',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: isArabic ? 'إخفاء' : 'Hide',
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
