import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/activity_hub/application/providers/activity_hub_provider.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_create_sheet.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_empty_state.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_request_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_backend_notice_banner.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_error_widget.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_loading_widget.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_section_header.dart';

class RfqTabView extends ConsumerWidget {
  const RfqTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final state = ref.watch(rfqProvider);
    final query = ref
        .watch(activityHubControllerProvider.select((s) => s.searchQuery))
        .trim()
        .toLowerCase();
    final hPad = context.horizontalScreenPadding;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, 0),
          child: Row(
            children: [
              Expanded(
                child: ActivitySectionHeader(title: l10n.rfqTitle),
              ),
              ActivityActionButton(
                label: l10n.rfqCreateAction,
                icon: Icons.add_rounded,
                onPressed: () => RfqCreateSheet.show(context),
              ),
            ],
          ),
        ),
        if (!state.isBackendSupported)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.sm, hPad, 0),
            child: ActivityBackendNoticeBanner(
              message: l10n.rfqBackendUnavailableNotice,
            ),
          ),
        Expanded(
          child: state.items.when(
            loading: () => const ActivityLoadingWidget(),
            error: (err, _) => ActivityErrorWidget(
              error: err,
              onRetry: () => ref.read(rfqProvider.notifier).loadRfqs(),
            ),
            data: (rfqs) {
              final filtered = query.isEmpty
                  ? rfqs
                  : rfqs
                        .where(
                          (r) =>
                              r.title.toLowerCase().contains(query) ||
                              r.referenceNumber.toLowerCase().contains(query) ||
                              r.materialsSummary.toLowerCase().contains(query),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(rfqProvider.notifier).loadRfqs(refresh: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 40),
                      RfqEmptyState(
                        onCreateTap: () => RfqCreateSheet.show(context),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(rfqProvider.notifier).loadRfqs(refresh: true),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.md,
                    hPad,
                    AppSpacing.xxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final rfq = filtered[index];
                    return RfqRequestCard(
                      rfq: rfq,
                      onAcceptQuotation: (qId) => ref
                          .read(rfqProvider.notifier)
                          .acceptQuotation(rfq.id, qId),
                      onRejectQuotation: (qId) => ref
                          .read(rfqProvider.notifier)
                          .rejectQuotation(rfq.id, qId),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
