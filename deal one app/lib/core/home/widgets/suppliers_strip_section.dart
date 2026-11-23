import 'package:flutter/material.dart';

import 'package:market_space/core/design_system/deal_one_section_chrome.dart';
import 'package:market_space/core/home/widgets/supplier_card_widget.dart';
import 'package:market_space/core/marketplace/section_home_models.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// Shared horizontal strip of verified suppliers, service centers, or sellers.
class SuppliersStripSection extends StatelessWidget {
  final String sectionKey;
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final List<SectionProviderItem> providers;
  final ValueChanged<SectionProviderItem>? onProviderTap;

  const SuppliersStripSection({
    super.key,
    required this.sectionKey,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    required this.providers,
    this.onProviderTap,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();
    final hPad = context.horizontalScreenPadding;

    return Column(
      key: Key('suppliers_strip_$sectionKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DealOneSectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        SizedBox(
          height: 84,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return SupplierCardWidget(
                provider: provider,
                onTap: onProviderTap != null
                    ? () => onProviderTap!(provider)
                    : onActionTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
