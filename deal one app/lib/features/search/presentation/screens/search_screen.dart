import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/features/categories/domain/entities/category_entity.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/listings/presentation/widgets/deal_one_listing_card.dart';
import 'package:market_space/features/search/data/dto/search_dto.dart';
import 'package:market_space/features/search/presentation/providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(searchActiveQueryDtoProvider).query;
    if (initial.isNotEmpty) {
      _controller.text = initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final current = ref.read(searchActiveQueryDtoProvider);
      ref.read(searchActiveQueryDtoProvider.notifier).state = current.copyWith(
        query: val,
        page: 1,
      );
    });
  }

  void _selectCategory(String? slug) {
    final current = ref.read(searchActiveQueryDtoProvider);
    ref.read(searchActiveQueryDtoProvider.notifier).state = SearchQueryDto(
      query: current.query,
      categorySlug: slug,
      governorateId: current.governorateId,
      cityId: current.cityId,
      sort: current.sort,
      page: 1,
    );
  }

  void _changeSort(String sort) {
    final current = ref.read(searchActiveQueryDtoProvider);
    ref.read(searchActiveQueryDtoProvider.notifier).state = current.copyWith(
      sort: sort,
      page: 1,
    );
  }

  void _changePage(int page) {
    final current = ref.read(searchActiveQueryDtoProvider);
    ref.read(searchActiveQueryDtoProvider.notifier).state = current.copyWith(
      page: page,
    );
  }

  void _openDynamicFilterSheet(
    BuildContext context,
    CategoryItem? activeRootCategory,
  ) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final current = ref.read(searchActiveQueryDtoProvider);
    final minPriceCtrl = TextEditingController(
      text: current.minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceCtrl = TextEditingController(
      text: current.maxPrice?.toStringAsFixed(0) ?? '',
    );
    final brandCtrl = TextEditingController(text: current.brand ?? '');
    final yearCtrl = TextEditingController(
      text: current.year?.toString() ?? '',
    );
    final sizeCtrl = TextEditingController(text: current.size ?? '');
    final colorCtrl = TextEditingController(text: current.color ?? '');

    String? listingKind = current.listingKind;
    int? rooms = current.rooms;
    int? baths = current.baths;
    String? transmission = current.transmission;
    String? condition = current.condition;

    final rootSlug = (activeRootCategory?.slug ?? current.categorySlug ?? '')
        .toLowerCase();
    final isRealEstate = rootSlug.contains('real') ||
        rootSlug.contains('apartment') ||
        rootSlug.contains('villa') ||
        rootSlug.contains('land');
    final isCars = rootSlug.contains('car') ||
        rootSlug.contains('sedan') ||
        rootSlug.contains('suv');
    final isFashion = rootSlug.contains('fashion') ||
        rootSlug.contains('cloth') ||
        rootSlug.contains('shoe');
    final isAppliances = rootSlug.contains('appliance') ||
        rootSlug.contains('decor') ||
        rootSlug.contains('furniture');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'فلاتر البحث' : 'Filters',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(searchActiveQueryDtoProvider.notifier)
                                .state = SearchQueryDto(
                              query: current.query,
                              categorySlug: current.categorySlug,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(isArabic ? 'مسح الكل' : 'Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic ? 'نطاق السعر (ج.م)' : 'Price Range (EGP)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: isArabic ? 'من' : 'Min',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: maxPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: isArabic ? 'إلى' : 'Max',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Real Estate dynamic filters
                    if (isRealEstate) ...[
                      Text(
                        isArabic ? 'نوع العرض' : 'Listing Type',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(isArabic ? 'الكل' : 'All'),
                            selected: listingKind == null,
                            onSelected: (_) =>
                                setModalState(() => listingKind = null),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'للبيع' : 'For Sale'),
                            selected: listingKind == 'sale',
                            onSelected: (_) =>
                                setModalState(() => listingKind = 'sale'),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'للإيجار' : 'For Rent'),
                            selected: listingKind == 'rent',
                            onSelected: (_) =>
                                setModalState(() => listingKind = 'rent'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'عدد الغرف' : 'Rooms',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [null, 1, 2, 3, 4, 5].map((r) {
                          return ChoiceChip(
                            label: Text(
                              r == null ? (isArabic ? 'الكل' : 'Any') : '$r',
                            ),
                            selected: rooms == r,
                            onSelected: (_) => setModalState(() => rooms = r),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'عدد الحمامات' : 'Bathrooms',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [null, 1, 2, 3, 4].map((b) {
                          return ChoiceChip(
                            label: Text(
                              b == null ? (isArabic ? 'الكل' : 'Any') : '$b',
                            ),
                            selected: baths == b,
                            onSelected: (_) => setModalState(() => baths = b),
                          );
                        }).toList(),
                      ),
                    ],

                    // Cars dynamic filters
                    if (isCars) ...[
                      TextField(
                        controller: brandCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'الماركة (مثال: تويوتا)' : 'Brand',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'سنة الصنع' : 'Year',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(isArabic ? 'الكل' : 'Any'),
                            selected: transmission == null,
                            onSelected: (_) =>
                                setModalState(() => transmission = null),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'أوتوماتيك' : 'Automatic'),
                            selected: transmission == 'أوتوماتيك',
                            onSelected: (_) =>
                                setModalState(() => transmission = 'أوتوماتيك'),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'مانيوال' : 'Manual'),
                            selected: transmission == 'مانيوال',
                            onSelected: (_) =>
                                setModalState(() => transmission = 'مانيوال'),
                          ),
                        ],
                      ),
                    ],

                    // Fashion dynamic filters
                    if (isFashion) ...[
                      TextField(
                        controller: sizeCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'المقاس (S, M, L, XL)' : 'Size',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: colorCtrl,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'اللون' : 'Color',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],

                    // Appliances / General condition filter
                    if (isAppliances || (!isRealEstate && !isCars && !isFashion)) ...[
                      if (isAppliances) ...[
                        TextField(
                          controller: brandCtrl,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'الماركة' : 'Brand',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        isArabic ? 'الحالة' : 'Condition',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(isArabic ? 'الكل' : 'All'),
                            selected: condition == null,
                            onSelected: (_) =>
                                setModalState(() => condition = null),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'جديد' : 'New'),
                            selected: condition == 'NEW',
                            onSelected: (_) =>
                                setModalState(() => condition = 'NEW'),
                          ),
                          ChoiceChip(
                            label: Text(isArabic ? 'مستعمل' : 'Used'),
                            selected: condition == 'USED',
                            onSelected: (_) =>
                                setModalState(() => condition = 'USED'),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DealOneDesignColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final minP = double.tryParse(minPriceCtrl.text.trim());
                          final maxP = double.tryParse(maxPriceCtrl.text.trim());
                          final yr = int.tryParse(yearCtrl.text.trim());
                          ref.read(searchActiveQueryDtoProvider.notifier)
                              .state = current.copyWith(
                            minPrice: minP,
                            clearMinPrice: minP == null,
                            maxPrice: maxP,
                            clearMaxPrice: maxP == null,
                            listingKind: listingKind,
                            clearListingKind: listingKind == null,
                            rooms: rooms,
                            clearRooms: rooms == null,
                            baths: baths,
                            clearBaths: baths == null,
                            brand: brandCtrl.text.trim().isNotEmpty
                                ? brandCtrl.text.trim()
                                : null,
                            clearBrand: brandCtrl.text.trim().isEmpty,
                            year: yr,
                            clearYear: yr == null,
                            transmission: transmission,
                            clearTransmission: transmission == null,
                            size: sizeCtrl.text.trim().isNotEmpty
                                ? sizeCtrl.text.trim()
                                : null,
                            clearSize: sizeCtrl.text.trim().isEmpty,
                            color: colorCtrl.text.trim().isNotEmpty
                                ? colorCtrl.text.trim()
                                : null,
                            clearColor: colorCtrl.text.trim().isEmpty,
                            condition: condition,
                            clearCondition: condition == null,
                            page: 1,
                          );
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          isArabic ? 'تطبيق الفلاتر' : 'Apply Filters',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final activeDto = ref.watch(searchActiveQueryDtoProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(categoryTreeProvider);

    CategoryItem? activeRootCategory;
    categoriesAsync.whenData((cats) {
      for (final root in cats) {
        if (root.slug == activeDto.categorySlug ||
            root.subcategories.any((s) => s.slug == activeDto.categorySlug)) {
          activeRootCategory = root;
          break;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: isArabic
                ? 'ابحث عن عقار، سيارة، جهاز، أو خدمة...'
                : 'Search properties, cars, appliances...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onQueryChanged,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: isArabic ? 'فلاتر' : 'Filters',
            onPressed: () =>
                _openDynamicFilterSheet(context, activeRootCategory),
          ),
        ],
      ),
      body: Column(
        children: [
          // Root Categories bar
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: Text(isArabic ? 'الكل' : 'All'),
                      selected: activeDto.categorySlug == null,
                      onSelected: (_) => _selectCategory(null),
                    );
                  }
                  final cat = categories[index - 1];
                  final selected = activeRootCategory?.slug == cat.slug;
                  return ChoiceChip(
                    label: Text(isArabic ? cat.nameAr : cat.nameEn),
                    selected: selected,
                    onSelected: (_) => _selectCategory(cat.slug),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 46),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Subcategories bar (when a root category is selected)
          if (activeRootCategory != null &&
              activeRootCategory!.subcategories.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: activeRootCategory!.subcategories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final allRootSelected =
                        activeDto.categorySlug == activeRootCategory!.slug;
                    return FilterChip(
                      label: Text(
                        isArabic
                            ? 'كل ${activeRootCategory!.nameAr}'
                            : 'All ${activeRootCategory!.nameEn}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: allRootSelected,
                      onSelected: (_) =>
                          _selectCategory(activeRootCategory!.slug),
                    );
                  }
                  final sub = activeRootCategory!.subcategories[index - 1];
                  final isSelected = activeDto.categorySlug == sub.slug;
                  return FilterChip(
                    label: Text(
                      isArabic ? sub.nameAr : sub.nameEn,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(sub.slug),
                  );
                },
              ),
            ),

          // Sort & Results count bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                searchAsync.maybeWhen(
                  data: (res) => Text(
                    isArabic
                        ? '${res.totalCount} نتيجة'
                        : '${res.totalCount} results',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                DropdownButton<String>(
                  value: activeDto.sort,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text(isArabic ? 'الأحدث' : 'Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text(
                        isArabic ? 'السعر: من الأقل' : 'Price: Low to High',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text(
                        isArabic ? 'السعر: من الأعلى' : 'Price: High to Low',
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) _changeSort(val);
                  },
                ),
              ],
            ),
          ),

          // Results Grid + Pagination
          Expanded(
            child: searchAsync.when(
              data: (result) {
                if (result.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textMutedOf(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic
                              ? 'لا توجد نتائج مطابقة للفلاتر الحالية'
                              : 'No matching listings found',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: result.items.length,
                        itemBuilder: (context, index) =>
                            DealOneListingCard(item: result.items[index]),
                      ),
                    ),
                    if (result.totalPages > 1)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: result.currentPage > 1
                                    ? () => _changePage(result.currentPage - 1)
                                    : null,
                                child: Text(isArabic ? 'السابق' : 'Previous'),
                              ),
                              Text(
                                '${result.currentPage} / ${result.totalPages}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              OutlinedButton(
                                onPressed:
                                    result.currentPage < result.totalPages
                                        ? () =>
                                            _changePage(result.currentPage + 1)
                                        : null,
                                child: Text(isArabic ? 'التالي' : 'Next'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.errorOf(context),
                    ),
                    const SizedBox(height: 8),
                    Text(isArabic ? 'خطأ في البحث: $err' : 'Search error: $err'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(searchResultsProvider),
                      child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
