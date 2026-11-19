import 'package:flutter/material.dart';

import '../marketplace/section_home_controller.dart';
import '../marketplace/section_home_models.dart';
import '../theme/app_colors.dart';

/// Server-driven Section Filter Bottom Sheet.
/// Renders ONLY the filter fields declared by Backend `SectionFilterConfig` for
/// the active section. Changes are buffered locally and submitted in a single
/// server-side request when the user taps "Apply Filters".
Future<SectionFilterState?> showServerDrivenFilterSheet({
  required BuildContext context,
  required SectionFilterConfig filterConfig,
  required SectionFilterState currentFilters,
}) {
  return showModalBottomSheet<SectionFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ServerDrivenFilterSheetBody(
      filterConfig: filterConfig,
      initial: currentFilters,
    ),
  );
}

class _ServerDrivenFilterSheetBody extends StatefulWidget {
  final SectionFilterConfig filterConfig;
  final SectionFilterState initial;

  const _ServerDrivenFilterSheetBody({
    required this.filterConfig,
    required this.initial,
  });

  @override
  State<_ServerDrivenFilterSheetBody> createState() =>
      _ServerDrivenFilterSheetBodyState();
}

class _ServerDrivenFilterSheetBodyState
    extends State<_ServerDrivenFilterSheetBody> {
  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  final Map<String, TextEditingController> _textControllers = {};

  String? _listingKind;
  String? _condition;
  late String _sort;
  late Map<String, dynamic> _dynamicValues;

  @override
  void initState() {
    super.initState();
    _minPriceCtrl = TextEditingController(
      text: widget.initial.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceCtrl = TextEditingController(
      text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '',
    );
    _listingKind = widget.initial.listingKind;
    _condition = widget.initial.condition;
    _sort = widget.initial.sort;
    _dynamicValues = Map<String, dynamic>.from(widget.initial.dynamicFilters);

    for (final field in widget.filterConfig.fields) {
      if (field.type == 'text' || field.type == 'number') {
        _textControllers[field.key] = TextEditingController(
          text: _dynamicValues[field.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _minPriceCtrl.clear();
      _maxPriceCtrl.clear();
      for (final ctrl in _textControllers.values) {
        ctrl.clear();
      }
      _listingKind = null;
      _condition = null;
      _sort = 'newest';
      _dynamicValues = {};
    });
  }

  void _apply() {
    final mergedDynamic = Map<String, dynamic>.from(_dynamicValues);
    for (final field in widget.filterConfig.fields) {
      final ctrl = _textControllers[field.key];
      if (ctrl != null) {
        final raw = ctrl.text.trim();
        if (raw.isEmpty) {
          mergedDynamic.remove(field.key);
        } else if (field.type == 'number') {
          final parsed = num.tryParse(raw);
          if (parsed != null) mergedDynamic[field.key] = parsed;
        } else {
          mergedDynamic[field.key] = raw;
        }
      }
    }

    Navigator.of(context).pop(
      SectionFilterState(
        subcategorySlug: widget.initial.subcategorySlug,
        searchQuery: widget.initial.searchQuery,
        listingKind: _listingKind,
        condition: _condition,
        minPrice: double.tryParse(_minPriceCtrl.text.trim()),
        maxPrice: double.tryParse(_maxPriceCtrl.text.trim()),
        sort: _sort,
        dynamicFilters: mergedDynamic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final cfg = widget.filterConfig;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'تصفية النتائج' : 'Filter Results',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetAll,
                      child: Text(isArabic ? 'مسح الكل' : 'Reset All'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. Sort Options (Server-Driven)
                    if (cfg.sortOptions.isNotEmpty) ...[
                      _FilterLabel(isArabic ? 'الترتيب حسب' : 'Sort By'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cfg.sortOptions.map((opt) {
                          final selected = _sort == opt.value;
                          return ChoiceChip(
                            label: Text(opt.localizedLabel(isArabic)),
                            selected: selected,
                            selectedColor: DealOneDesignColors.navy,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) =>
                                setState(() => _sort = opt.value),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Listing Kind (Sale / Rent — only when backend supports it)
                    if (cfg.supportsListingKind &&
                        cfg.listingKindOptions.isNotEmpty) ...[
                      _FilterLabel(isArabic ? 'نوع العرض' : 'Offer Type'),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(isArabic ? 'الكل' : 'All'),
                            selected: _listingKind == null,
                            onSelected: (_) =>
                                setState(() => _listingKind = null),
                          ),
                          ...cfg.listingKindOptions.map((opt) {
                            final selected = _listingKind == opt.value;
                            return ChoiceChip(
                              label: Text(opt.localizedLabel(isArabic)),
                              selected: selected,
                              selectedColor: DealOneDesignColors.navy,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => setState(
                                () => _listingKind = selected ? null : opt.value,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Price Range
                    if (cfg.supportsPriceRange) ...[
                      _FilterLabel(
                        isArabic ? 'نطاق السعر (ج.م)' : 'Price Range (EGP)',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'من' : 'Min',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: isArabic ? 'إلى' : 'Max',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 4. Condition (only when backend supports it)
                    if (cfg.supportsCondition) ...[
                      _FilterLabel(isArabic ? 'الحالة' : 'Condition'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final entry in [
                            ('NEW', isArabic ? 'جديد' : 'New'),
                            ('USED', isArabic ? 'مستعمل' : 'Used'),
                          ])
                            ChoiceChip(
                              label: Text(entry.$2),
                              selected: _condition == entry.$1,
                              selectedColor: DealOneDesignColors.navy,
                              labelStyle: TextStyle(
                                color: _condition == entry.$1
                                    ? Colors.white
                                    : null,
                              ),
                              onSelected: (sel) => setState(
                                () => _condition = sel ? entry.$1 : null,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 5. Server-Driven Dynamic Section Fields (CategoryField)
                    for (final field in cfg.fields) ...[
                      _buildDynamicField(field, isArabic),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DealOneDesignColors.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _apply,
                    child: Text(
                      isArabic ? 'تطبيق الفلاتر' : 'Apply Filters',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicField(SectionFilterField field, bool isArabic) {
    final label = field.localizedLabel(isArabic);

    if (field.type == 'boolean') {
      final value = _dynamicValues[field.key] == true;
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        value: value,
        onChanged: (v) {
          setState(() {
            if (v) {
              _dynamicValues[field.key] = true;
            } else {
              _dynamicValues.remove(field.key);
            }
          });
        },
      );
    }

    if ((field.type == 'select' || field.type == 'multi_select') &&
        field.options.isNotEmpty) {
      final selectedVal = _dynamicValues[field.key]?.toString();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterLabel(label),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: field.options.map((opt) {
              final isSel = selectedVal == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: isSel,
                selectedColor: DealOneDesignColors.navy,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : null,
                  fontSize: 12.5,
                ),
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _dynamicValues[field.key] = opt;
                    } else {
                      _dynamicValues.remove(field.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    final ctrl = _textControllers.putIfAbsent(
      field.key,
      () => TextEditingController(
        text: _dynamicValues[field.key]?.toString() ?? '',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        TextField(
          controller: ctrl,
          keyboardType: field.type == 'number'
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;

  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
