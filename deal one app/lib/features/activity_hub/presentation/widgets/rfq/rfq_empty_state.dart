import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_empty_widget.dart';

class RfqEmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const RfqEmptyState({super.key, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return ActivityEmptyWidget(
      title: l10n.rfqEmptyTitle,
      message: l10n.rfqEmptyMessage,
      icon: Icons.request_quote_outlined,
      actionLabel: l10n.rfqCreateAction,
      onActionTap: onCreateTap,
    );
  }
}
