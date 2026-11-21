import 'package:flutter/material.dart';

import 'package:market_space/shared/widgets/app_empty_state.dart';

class ActivityEmptyWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const ActivityEmptyWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: icon,
      action: actionLabel != null && onActionTap != null
          ? ElevatedButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            )
          : null,
    );
  }
}
