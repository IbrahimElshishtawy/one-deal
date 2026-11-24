import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/domain/entities/conversation_entity.dart';

/// Independent linked marketplace listing pill shown inside an inbox tile.
class InboxListingChip extends StatelessWidget {
  final ConversationListingPreview listing;
  final ChatColorTheme colorTheme;

  const InboxListingChip({
    super.key,
    required this.listing,
    this.colorTheme = ChatColorTheme.dealOneNavy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DealOneTokens.softTileBgOf(context),
        borderRadius: AppRadii.md,
      ),
      child: Row(
        children: [
          Icon(Icons.apartment_rounded, size: 15, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
          ),
          if (listing.price > 0) ...[
            const SizedBox(width: 6),
            Text(
              formatDealOnePrice(listing.price, isArabic: isArabic),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.amber,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
