import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

class MarketBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onAddListingTap;

  const MarketBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onIndexChanged,
    this.onAddListingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        boxShadow: AppColors.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10.0,
                  offset: const Offset(0, -3),
                ),
              ],
        border: Border(top: BorderSide(color: AppColors.borderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: isCompact ? 60.0 : 66.0,
          child: Row(
            children: [
              // 1. الرئيسية (Home)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isCompact: isCompact,
                ),
              ),

              // 2. جولات فيديو (Video Tours)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.play_circle_outline_rounded,
                  label: 'جولات فيديو',
                  isCompact: isCompact,
                  hasLiveDot: true,
                ),
              ),

              // 3. Center Action (+ أضف إعلانك)
              Expanded(child: _buildCenterAddButton(context, isCompact)),

              // 4. الرسائل (Messages with badge)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Icons.chat_outlined,
                  label: 'الرسائل',
                  isCompact: isCompact,
                  badgeCount: 2,
                ),
              ),

              // 5. حسابي (Profile)
              Expanded(
                child: _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.person_outline_rounded,
                  label: 'حسابي',
                  isCompact: isCompact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isCompact,
    bool hasLiveDot = false,
    int? badgeCount,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? AppColors.primaryOf(context)
        : AppColors.iconSecondaryOf(context);

    return InkWell(
      onTap: () => onIndexChanged?.call(index),
      borderRadius: AppRadii.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: isCompact ? 22.0 : 25.0, color: color),
                if (hasLiveDot)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 6.5,
                      height: 6.5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      constraints: const BoxConstraints(
                        minWidth: 15.0,
                        minHeight: 15.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onPrimaryOf(context),
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3.0),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 11.0 : 12.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context, bool isCompact) {
    return InkWell(
      onTap: onAddListingTap,
      borderRadius: AppRadii.full,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isCompact ? 36.0 : 42.0,
            height: isCompact ? 36.0 : 42.0,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context),
              shape: BoxShape.circle,
              boxShadow: AppColors.isDark(context)
                  ? const []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Icon(
              Icons.add_rounded,
              color: AppColors.onPrimaryOf(context),
              size: isCompact ? 22.0 : 26.0,
            ),
          ),
          const SizedBox(height: 2.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'أضف إعلانك',
              style: TextStyle(
                fontSize: isCompact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
