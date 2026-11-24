import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:market_space/core/routing/route_names.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Buyer-facing Request-a-Quote (RFQ) call-to-action card for Building Materials
/// & Electrical Supplies Home Page. Navigates directly to the existing RFQ tab
/// inside Activity Hub (`RouteNames.activityHubFor(tab: 'rfq')`).
class BuyerRfqCtaCard extends StatelessWidget {
  const BuyerRfqCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;

    return Padding(
      key: const Key('building_materials_buyer_rfq_cta'),
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 4),
      child: Material(
        color: DealOneDesignColors.navy,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(
            RouteNames.activityHubFor(
              tab: 'rfq',
              categorySlug: 'building-materials',
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'اطلب عرض سعر لمشروعك'
                            : 'Request a Quote (RFQ)',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isArabic
                            ? 'قارن أسعار الحديد والأسمنت والتوريدات من موردين معتمدين'
                            : 'Compare quotes from verified building material suppliers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
