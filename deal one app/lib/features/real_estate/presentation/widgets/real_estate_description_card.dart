import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Expandable description card matching `Real Estate Details.png`.
class RealEstateDescriptionCard extends StatefulWidget {
  final String description;

  const RealEstateDescriptionCard({super.key, required this.description});

  @override
  State<RealEstateDescriptionCard> createState() =>
      _RealEstateDescriptionCardState();
}

class _RealEstateDescriptionCardState extends State<RealEstateDescriptionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final trimmed = widget.description.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final canCollapse = trimmed.length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 19,
              color: DealOneTokens.textPrimaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'الوصف التفصيلي' : 'Detailed Description',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: DealOneTokens.cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _expanded || !canCollapse
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Text(
                  trimmed,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                secondChild: Text(
                  trimmed,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              if (canCollapse) ...[
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: DealOneTokens.cardBorderOf(context)),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _expanded
                          ? (isArabic ? 'إخفاء بعض التفاصيل' : 'Show Less')
                          : (isArabic ? 'عرض الوصف بالكامل' : 'Read More'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
