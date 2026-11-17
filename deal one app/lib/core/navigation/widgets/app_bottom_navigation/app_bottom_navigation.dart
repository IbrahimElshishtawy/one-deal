import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../notifications/presentation/state/notification_controller.dart';
import '../../config/section_navigation_config.dart';
import 'navigation_layout.dart';
import 'navigation_tab_item.dart';

class AppBottomNavigation extends StatelessWidget {
  final SectionNavigationConfig config;
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onFloatingActionPressed;
  final NotificationController? notificationController;
  final bool isVisible;
  final bool showFloatingAction;

  const AppBottomNavigation({
    super.key,
    required this.config,
    this.currentIndex = 0,
    this.onTabSelected,
    this.onFloatingActionPressed,
    this.notificationController,
    this.isVisible = true,
    this.showFloatingAction = false,
  });

  void _handleFabPressed(BuildContext context) {
    if (onFloatingActionPressed != null) {
      onFloatingActionPressed!();
      return;
    }

    final fab = config.floatingAction;
    if (fab?.onPressed != null) {
      fab!.onPressed!();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${fab?.label ?? "أضف إعلانك"} في قسم ${config.sectionName}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.isCompactPhone;
    final fab = showFloatingAction ? config.floatingAction : null;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1.8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.only(
            left: NavigationLayout.horizontalMargin,
            right: NavigationLayout.horizontalMargin,
            bottom: NavigationLayout.bottomMargin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Floating Action Button across all sections
              if (fab != null) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                    left: 4.0,
                    right: 4.0,
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'fab_${config.sectionId}',
                    onPressed: () => _handleFabPressed(context),
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: AppColors.onPrimaryOf(context),
                    elevation: 4.0,
                    icon: Icon(
                      fab.icon,
                      color: AppColors.onPrimaryOf(context),
                      size: 20.0,
                    ),
                    label: Text(
                      fab.label,
                      style: TextStyle(
                        color: AppColors.onPrimaryOf(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              // 5-Item Navigation Container
              Container(
                decoration: BoxDecoration(
                  color: NavigationLayout.backgroundColorOf(context),
                  borderRadius: NavigationLayout.borderRadius,
                  boxShadow: NavigationLayout.containerShadowOf(context),
                  border: NavigationLayout.containerBorderOf(context),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: NavigationLayout.getBarHeight(isCompact),
                    child: ListenableBuilder(
                      listenable: notificationController ?? ValueNotifier(null),
                      builder: (context, _) {
                        return Row(
                          children: List.generate(config.items.length, (index) {
                            final item = config.items[index];
                            final badgeKey = item.badgeKey;
                            final badgeCount =
                                (badgeKey != null &&
                                    notificationController != null)
                                ? notificationController!.getUnreadCount(
                                    badgeKey,
                                  )
                                : 0;

                            return Expanded(
                              child: NavigationTabItem(
                                item: item,
                                isSelected: currentIndex == index,
                                isCompact: isCompact,
                                badgeCount: badgeCount,
                                onTap: () => onTabSelected?.call(index),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
