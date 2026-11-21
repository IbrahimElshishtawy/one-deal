import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_quotation_card.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/rfq/rfq_status_badge.dart';

class RfqRequestCard extends StatefulWidget {
  final RfqRequestEntity rfq;
  final void Function(String quotationId)? onAcceptQuotation;
  final void Function(String quotationId)? onRejectQuotation;

  const RfqRequestCard({
    super.key,
    required this.rfq,
    this.onAcceptQuotation,
    this.onRejectQuotation,
  });

  @override
  State<RfqRequestCard> createState() => _RfqRequestCardState();
}

class _RfqRequestCardState extends State<RfqRequestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final rfq = widget.rfq;
    final submittedDate = DateFormat.yMMMd(locale).format(rfq.submittedAt);
    final updatedDate = rfq.updatedAt != null
        ? DateFormat.yMMMd(locale).format(rfq.updatedAt!)
        : submittedDate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.rfqReferenceLabel(rfq.referenceNumber),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
              RfqStatusBadge(status: rfq.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rfq.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                l10n.rfqSubmittedDateLabel(submittedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              Text(
                l10n.rfqItemsCountLabel(rfq.requestedItemsCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                l10n.rfqQuotationsCountLabel(rfq.quotationsCount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.infoOf(context),
                ),
              ),
              Text(
                l10n.rfqLastUpdatedLabel(updatedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
            ),
            label: Text(l10n.rfqViewQuotationsAction),
          ),
          if (_expanded) ...[
            const Divider(height: AppSpacing.md),
            if (rfq.quotations.isEmpty)
              Text(
                l10n.rfqNoQuotationsYet,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMutedOf(context),
                ),
              )
            else
              Column(
                children: rfq.quotations
                    .map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: RfqQuotationCard(
                          quotation: q,
                          onAccept: widget.onAcceptQuotation != null
                              ? () => widget.onAcceptQuotation!(q.id)
                              : null,
                          onReject: widget.onRejectQuotation != null
                              ? () => widget.onRejectQuotation!(q.id)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }
}
