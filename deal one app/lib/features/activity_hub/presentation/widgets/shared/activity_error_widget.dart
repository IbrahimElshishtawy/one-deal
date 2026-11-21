import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/errors/error_presenter.dart';
import 'package:market_space/shared/widgets/app_error_view.dart';

class ActivityErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ActivityErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final presented = ErrorPresenter.present(error, isArabic: isArabic);
    final l10n = AppLocalization.of(context);

    return AppErrorView(
      title: presented.title,
      message: presented.message,
      onRetry: presented.canRetry ? onRetry : null,
      retryButtonLabel: l10n.retry,
    );
  }
}
