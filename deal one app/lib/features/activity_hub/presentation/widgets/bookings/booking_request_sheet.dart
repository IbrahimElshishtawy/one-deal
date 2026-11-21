import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/application/providers/bookings_provider.dart';
import 'package:market_space/features/activity_hub/domain/entities/booking_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_backend_notice_banner.dart';

/// Modal bottom sheet for scheduling a Property Viewing, Vehicle Inspection,
/// or Home/Engineering Service appointment.
class BookingRequestSheet extends ConsumerStatefulWidget {
  final String? listingId;
  final String title;
  final String providerName;
  final BookingCategory category;
  final BookingType defaultType;

  const BookingRequestSheet({
    super.key,
    this.listingId,
    required this.title,
    required this.providerName,
    required this.category,
    required this.defaultType,
  });

  static Future<void> show(
    BuildContext context, {
    String? listingId,
    required String title,
    required String providerName,
    required BookingCategory category,
    required BookingType defaultType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingRequestSheet(
        listingId: listingId,
        title: title,
        providerName: providerName,
        category: category,
        defaultType: defaultType,
      ),
    );
  }

  @override
  ConsumerState<BookingRequestSheet> createState() =>
      _BookingRequestSheetState();
}

class _BookingRequestSheetState extends ConsumerState<BookingRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTime;
  late BookingType _selectedType;

  static const List<String> _timeSlots = [
    '10:00 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
    '06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<BookingType> _typesForCategory(BookingCategory cat) {
    switch (cat) {
      case BookingCategory.realEstate:
        return [
          BookingType.propertyViewing,
          BookingType.propertyInspection,
          BookingType.agentContact,
        ];
      case BookingCategory.carsMaintenance:
        return [
          BookingType.vehicleInspection,
          BookingType.maintenanceBooking,
          BookingType.serviceCenter,
        ];
      case BookingCategory.servicesEngineering:
        return [
          BookingType.plumbing,
          BookingType.electricity,
          BookingType.airConditioning,
          BookingType.construction,
          BookingType.engineering,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final bookingsState = ref.watch(bookingsProvider);
    final locale = Localizations.localeOf(context).languageCode;

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
                  l10n.bookingsCreateTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.title} • ${widget.providerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMutedOf(context)),
                ),
                if (!bookingsState.isBackendSupported) ...[
                  const SizedBox(height: AppSpacing.md),
                  ActivityBackendNoticeBanner(
                    message: l10n.bookingsBackendUnavailableNotice,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _typesForCategory(widget.category).map((t) {
                    return ChoiceChip(
                      label: Text(ActivityHubL10n.bookingTypeLabel(context, t)),
                      selected: _selectedType == t,
                      onSelected: (_) => setState(() => _selectedType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  label: Text(
                    _selectedDate != null
                        ? DateFormat.yMMMd(locale).format(_selectedDate!)
                        : l10n.bookingsSelectDateHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: _timeSlots.map((slot) {
                    return ChoiceChip(
                      label: Text(slot),
                      selected: _selectedTime == slot,
                      onSelected: (_) => setState(() => _selectedTime = slot),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.bookingsAddressLabel,
                    hintText: l10n.bookingsAddressHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? l10n.bookingsValidationAddressRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: l10n.bookingsNotesHint,
                    border: const OutlineInputBorder(borderRadius: AppRadii.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ActivityActionButton(
                    label: l10n.bookingsSubmitAction,
                    isLoading: bookingsState.isMutating,
                    onPressed: bookingsState.isBackendSupported
                        ? () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.bookingsValidationDateRequired,
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.bookingsValidationTimeRequired,
                                  ),
                                ),
                              );
                              return;
                            }
                            final ok = await ref
                                .read(bookingsProvider.notifier)
                                .createBooking(
                                  CreateBookingPayload(
                                    listingId: widget.listingId,
                                    title: widget.title,
                                    providerName: widget.providerName,
                                    category: widget.category,
                                    type: _selectedType,
                                    date: _selectedDate!,
                                    timeSlot: _selectedTime!,
                                    address: _addressController.text.trim(),
                                    notes: _notesController.text.trim().isEmpty
                                        ? null
                                        : _notesController.text.trim(),
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
