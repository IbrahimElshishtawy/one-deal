import 'package:flutter/material.dart';
import 'package:market_space/features/locations/domain/entities/location_entity.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent side-by-side Governorate & City selector widget (`المحافظة والمدينة *`).
/// Supports loading shimmer, error retry, searchable sheets, Light/Dark themes, and RTL/LTR.
class GovernorateCitySelectorRow extends StatelessWidget {
  final List<GovernorateEntity> governorates;
  final int? selectedGovernorateId;
  final int? selectedCityId;
  final bool isLoadingLocations;
  final bool hasLocationsError;
  final VoidCallback? onRetryLocations;
  final ValueChanged<int> onGovernorateChanged;
  final ValueChanged<int> onCityChanged;
  final String? governorateError;
  final String? cityError;

  const GovernorateCitySelectorRow({
    super.key,
    required this.governorates,
    required this.selectedGovernorateId,
    required this.selectedCityId,
    required this.isLoadingLocations,
    required this.hasLocationsError,
    this.onRetryLocations,
    required this.onGovernorateChanged,
    required this.onCityChanged,
    this.governorateError,
    this.cityError,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final lang = isArabic ? 'ar' : 'en';

    final selectedGov = governorates
        .where((g) => g.id == selectedGovernorateId)
        .firstOrNull;
    final cities = selectedGov?.cities ?? const <CityEntity>[];
    final selectedCity =
        cities.where((c) => c.id == selectedCityId).firstOrNull;

    final combinedError = governorateError ?? cityError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: WizardTheme.primaryInk(context),
                  ),
                  children: [
                    TextSpan(
                      text: isArabic
                          ? 'المحافظة والمدينة'
                          : 'Governorate & City',
                    ),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: combinedError != null
                            ? WizardTheme.danger(context)
                            : WizardTheme.primaryInk(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasLocationsError && onRetryLocations != null)
              TextButton.icon(
                onPressed: onRetryLocations,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 15),
                label: Text(
                  isArabic ? 'تحديث المدن' : 'Retry',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoadingLocations && governorates.isEmpty)
          Row(
            children: [
              Expanded(child: _ShimmerFieldPlaceholder()),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerFieldPlaceholder()),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _SelectorBox(
                  key: const Key('wizard_governorate_selector'),
                  label: selectedGov?.localizedName(lang),
                  placeholder: isArabic ? 'المحافظة' : 'Governorate',
                  hasError: governorateError != null,
                  onTap: governorates.isEmpty
                      ? null
                      : () => _openGovSheet(context, lang),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectorBox(
                  key: const Key('wizard_city_selector'),
                  label: selectedCity?.localizedName(lang),
                  placeholder: isArabic ? 'المدينة' : 'City',
                  hasError: cityError != null,
                  onTap: selectedGov == null || cities.isEmpty
                      ? null
                      : () => _openCitySheet(context, cities, lang),
                ),
              ),
            ],
          ),
        if (combinedError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: WizardTheme.danger(context),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  combinedError,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WizardTheme.danger(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openGovSheet(BuildContext context, String lang) async {
    await _showListSheet<GovernorateEntity>(
      context: context,
      title: lang == 'ar' ? 'اختر المحافظة' : 'Select Governorate',
      items: governorates,
      labelOf: (g) => g.localizedName(lang),
      isSelected: (g) => g.id == selectedGovernorateId,
      itemKey: (g) => Key('gov_option_${g.id}'),
      onSelect: (g) => onGovernorateChanged(g.id),
    );
  }

  Future<void> _openCitySheet(
    BuildContext context,
    List<CityEntity> cities,
    String lang,
  ) async {
    await _showListSheet<CityEntity>(
      context: context,
      title: lang == 'ar' ? 'اختر المدينة' : 'Select City',
      items: cities,
      labelOf: (c) => c.localizedName(lang),
      isSelected: (c) => c.id == selectedCityId,
      itemKey: (c) => Key('city_option_${c.id}'),
      onSelect: (c) => onCityChanged(c.id),
    );
  }

  Future<void> _showListSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required Key Function(T) itemKey,
    required ValueChanged<T> onSelect,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WizardTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.68,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WizardTheme.border(sheetCtx),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: WizardTheme.primaryInk(sheetCtx),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: WizardTheme.border(sheetCtx),
                      ),
                      itemBuilder: (_, idx) {
                        final item = items[idx];
                        final active = isSelected(item);
                        return ListTile(
                          key: itemKey(item),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          title: Text(
                            labelOf(item),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  active ? FontWeight.w800 : FontWeight.w500,
                              color: active
                                  ? WizardTheme.primaryNavy(sheetCtx)
                                  : WizardTheme.primaryInk(sheetCtx),
                            ),
                          ),
                          trailing: active
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: WizardTheme.primaryNavy(sheetCtx),
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            onSelect(item);
                            Navigator.of(sheetCtx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectorBox extends StatelessWidget {
  final String? label;
  final String placeholder;
  final bool hasError;
  final VoidCallback? onTap;

  const _SelectorBox({
    super.key,
    required this.label,
    required this.placeholder,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = label != null && label!.isNotEmpty;
    final disabled = onTap == null;

    return Material(
      color: WizardTheme.cardBg(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? WizardTheme.danger(context)
                  : WizardTheme.border(context),
              width: hasError ? 1.4 : 1.0,
            ),
            boxShadow: WizardTheme.inputShadow(context),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? label! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                    color: hasValue
                        ? WizardTheme.primaryInk(context)
                        : WizardTheme.hintInk(context)
                            .withValues(alpha: disabled ? 0.65 : 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: WizardTheme.secondaryInk(context)
                    .withValues(alpha: disabled ? 0.45 : 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerFieldPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: WizardTheme.elevatedCardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WizardTheme.border(context)),
      ),
    );
  }
}
