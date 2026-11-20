import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Shared Search Bar matching all 7 Home reference PNGs:
/// - Sparkle + magnifying glass icon on start (right in RTL).
/// - Section-specific Arabic placeholder text in the center.
/// - Solid dark navy funnel icon (`Icons.filter_alt_rounded`) on end (left in RTL).
class DealOneSearchBar extends StatelessWidget {
  final String hintText;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  const DealOneSearchBar({
    super.key,
    required this.hintText,
    required this.onSearchTap,
    required this.onFilterTap,
    this.activeFilterCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = context.horizontalScreenPadding;
    final iconColor = isDark ? Colors.white : DealOneDesignColors.navy;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(hPad, 8, hPad, 12),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSearchTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : Colors.black.withValues(alpha: 0.06),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Magnifying glass with sparkle accent matching reference PNGs
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: iconColor,
                        size: 23,
                      ),
                      PositionedDirectional(
                        top: 1,
                        start: 1,
                        child: Icon(
                          Icons.auto_awesome,
                          color: iconColor,
                          size: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.filter_alt_rounded,
                          color: iconColor,
                          size: 22,
                        ),
                        if (activeFilterCount > 0)
                          PositionedDirectional(
                            top: -5,
                            end: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: const BoxDecoration(
                                color: DealOneDesignColors.amberPrice,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
