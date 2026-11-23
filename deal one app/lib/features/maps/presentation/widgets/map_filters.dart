import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Horizontal quick-filter chip bar for the active category, plus an explicit
/// opt-in chip to search across all Deal One categories when desired.
class MapFiltersBar extends StatelessWidget {
  final MapCategoryConfig config;
  final String activeFilterId;
  final bool searchAllCategories;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<bool> onSearchAllToggled;

  const MapFiltersBar({
    super.key,
    required this.config,
    required this.activeFilterId,
    required this.searchAllCategories,
    required this.onFilterSelected,
    required this.onSearchAllToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...config.quickFilters.map((filter) {
            final selected = activeFilterId == filter.id;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: _MapFilterChip(
                key: Key('map_filter_chip_${filter.id}'),
                label: filter.localizedLabel(isArabic),
                icon: filter.icon,
                selected: selected,
                selectedColor: config.accentColor,
                onTap: () => onFilterSelected(filter.id),
              ),
            );
          }),
          _MapFilterChip(
            key: const Key('map_filter_chip_all_categories'),
            label: isArabic ? 'جميع الأقسام' : 'All Categories',
            icon: Icons.public_rounded,
            selected: searchAllCategories,
            selectedColor: DealOneTokens.amber,
            onTap: () => onSearchAllToggled(!searchAllCategories),
          ),
        ],
      ),
    );
  }
}

/// Modal bottom sheet for advanced map filters (price range, verified only,
/// all-categories opt-in, reset).
class MapAdvancedFiltersResult {
  final bool verifiedOnly;
  final bool searchAllCategories;
  final double? minPrice;
  final double? maxPrice;
  final bool reset;

  const MapAdvancedFiltersResult({
    required this.verifiedOnly,
    required this.searchAllCategories,
    this.minPrice,
    this.maxPrice,
    this.reset = false,
  });
}

Future<MapAdvancedFiltersResult?> showMapAdvancedFiltersSheet({
  required BuildContext context,
  required MapCategoryConfig config,
  required bool verifiedOnly,
  required bool searchAllCategories,
  double? minPrice,
  double? maxPrice,
}) {
  return showModalBottomSheet<MapAdvancedFiltersResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _MapAdvancedFiltersSheet(
      config: config,
      initialVerifiedOnly: verifiedOnly,
      initialSearchAllCategories: searchAllCategories,
      initialMinPrice: minPrice,
      initialMaxPrice: maxPrice,
    ),
  );
}

class _MapAdvancedFiltersSheet extends StatefulWidget {
  final MapCategoryConfig config;
  final bool initialVerifiedOnly;
  final bool initialSearchAllCategories;
  final double? initialMinPrice;
  final double? initialMaxPrice;

  const _MapAdvancedFiltersSheet({
    required this.config,
    required this.initialVerifiedOnly,
    required this.initialSearchAllCategories,
    this.initialMinPrice,
    this.initialMaxPrice,
  });

  @override
  State<_MapAdvancedFiltersSheet> createState() =>
      _MapAdvancedFiltersSheetState();
}

class _MapAdvancedFiltersSheetState extends State<_MapAdvancedFiltersSheet> {
  late bool _verifiedOnly;
  late bool _searchAllCategories;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _verifiedOnly = widget.initialVerifiedOnly;
    _searchAllCategories = widget.initialSearchAllCategories;
    _minPriceController = TextEditingController(
      text: widget.initialMinPrice != null
          ? widget.initialMinPrice!.toStringAsFixed(0)
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialMaxPrice != null
          ? widget.initialMaxPrice!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      decoration: BoxDecoration(
        color: DealOneTokens.cardSurfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DealOneTokens.cardBorderOf(context),
                    borderRadius: AppRadii.full,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isArabic ? 'تصفية نتائج الخريطة' : 'Filter Map Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const MapAdvancedFiltersResult(
                          verifiedOnly: false,
                          searchAllCategories: false,
                          reset: true,
                        ),
                      );
                    },
                    child: Text(
                      isArabic ? 'إعادة ضبط' : 'Reset',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isArabic ? 'حسابات موثقة فقط' : 'Verified accounts only',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: _verifiedOnly,
                onChanged: (v) => setState(() => _verifiedOnly = v),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isArabic ? 'البحث في جميع الأقسام' : 'Search all categories',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  isArabic
                      ? 'افتراضياً تعرض الخريطة قسم ${widget.config.titleAr} فقط'
                      : 'By default the map shows only ${widget.config.titleEn}',
                  style: TextStyle(
                    fontSize: 12,
                    color: DealOneTokens.textSecondaryOf(context),
                  ),
                ),
                value: _searchAllCategories,
                onChanged: (v) => setState(() => _searchAllCategories = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isArabic ? 'نطاق السعر (ج.م)' : 'Price Range (EGP)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الحد الأدنى' : 'Min Price',
                        border: const OutlineInputBorder(
                          borderRadius: AppRadii.md,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الحد الأقصى' : 'Max Price',
                        border: const OutlineInputBorder(
                          borderRadius: AppRadii.md,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DealOneTokens.navy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.md,
                  ),
                ),
                onPressed: () {
                  final minVal = double.tryParse(
                    _minPriceController.text.trim(),
                  );
                  final maxVal = double.tryParse(
                    _maxPriceController.text.trim(),
                  );
                  Navigator.of(context).pop(
                    MapAdvancedFiltersResult(
                      verifiedOnly: _verifiedOnly,
                      searchAllCategories: _searchAllCategories,
                      minPrice: minVal,
                      maxPrice: maxVal,
                    ),
                  );
                },
                child: Text(
                  isArabic ? 'تطبيق الفلاتر' : 'Apply Filters',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _MapFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _MapFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedColor : DealOneTokens.cardSurfaceOf(context),
      borderRadius: AppRadii.full,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.full,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: AppRadii.full,
            border: Border.all(
              color: selected
                  ? selectedColor
                  : DealOneTokens.cardBorderOf(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? Colors.white
                    : DealOneTokens.textPrimaryOf(context),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : DealOneTokens.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
