import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/application/providers/rfq_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/rfq_entity.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_backend_notice_banner.dart';

class RfqCreateSheet extends ConsumerStatefulWidget {
  final String? initialMaterials;

  const RfqCreateSheet({super.key, this.initialMaterials});

  static Future<void> show(
    BuildContext context, {
    String? initialMaterials,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RfqCreateSheet(initialMaterials: initialMaterials),
    );
  }

  @override
  ConsumerState<RfqCreateSheet> createState() => _RfqCreateSheetState();
}

class _RfqCreateSheetState extends ConsumerState<RfqCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late final TextEditingController _materialsController;
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _materialsController = TextEditingController(
      text: widget.initialMaterials ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _materialsController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final rfqState = ref.watch(rfqProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rfqCreateTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!rfqState.isBackendSupported) ...[
                  const SizedBox(height: AppSpacing.md),
                  ActivityBackendNoticeBanner(
                    message: l10n.rfqBackendUnavailableNotice,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.rfqRequestTitleLabel,
                    hintText: l10n.rfqRequestTitleHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.rfqValidationTitleRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _materialsController,
                  decoration: InputDecoration(
                    labelText: l10n.rfqMaterialsLabel,
                    hintText: l10n.rfqMaterialsHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.rfqValidationMaterialsRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: l10n.rfqQuantityLabel,
                    hintText: l10n.rfqQuantityHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.rfqValidationQuantityRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: l10n.rfqDeliveryLocationLabel,
                    hintText: l10n.rfqDeliveryLocationHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l10n.rfqValidationLocationRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.rfqDescriptionLabel,
                    hintText: l10n.rfqDescriptionHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.rfqAttachmentsNote,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ActivityActionButton(
                    label: l10n.rfqSubmitAction,
                    isLoading: rfqState.isMutating,
                    onPressed: rfqState.isBackendSupported
                        ? () async {
                            if (!_formKey.currentState!.validate()) return;
                            final ok = await ref
                                .read(rfqProvider.notifier)
                                .createRfq(
                                  CreateRfqPayload(
                                    title: _titleController.text.trim(),
                                    materials: _materialsController.text.trim(),
                                    quantity: _quantityController.text.trim(),
                                    deliveryLocation: _locationController.text
                                        .trim(),
                                    description:
                                        _descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : _descriptionController.text.trim(),
                                  ),
                                );
                            if (ok && context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        : null,
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
