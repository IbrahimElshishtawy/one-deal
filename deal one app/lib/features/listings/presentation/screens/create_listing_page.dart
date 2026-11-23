import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/navigation/providers/section_navigation_provider.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/categories/presentation/providers/categories_providers.dart';
import 'package:market_space/features/listings/data/dto/listing_dto.dart';
import 'package:market_space/features/listings/presentation/providers/listings_providers.dart';
import 'package:market_space/features/listings/presentation/providers/seller_management_providers.dart';
import 'package:market_space/features/locations/presentation/providers/locations_providers.dart';
import 'package:market_space/features/maps/domain/entities/map_category_config.dart';

/// Category-aware Listing / Service / Product creation screen wired to
/// `POST /api/v1/listings`. Strictly gated by backend-verified seller capability.
class CreateListingPage extends ConsumerStatefulWidget {
  final String categorySlug;
  final String listingKind;

  const CreateListingPage({
    super.key,
    required this.categorySlug,
    this.listingKind = 'sale',
  });

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategoryId;
  int? _selectedCityId;
  bool _isSubmitting = false;
  String? _errorMessage;

  late final String _slug;

  @override
  void initState() {
    super.initState();
    _slug = MapCategoryRegistry.normalizeSlug(widget.categorySlug);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _headerTitle(bool isArabic) {
    if (widget.listingKind == 'service') {
      return isArabic ? 'إضافة خدمة جديدة' : 'Create Service';
    }
    if (widget.listingKind == 'product') {
      return isArabic ? 'إضافة منتج مواد بناء' : 'Add Material Product';
    }
    return isArabic ? 'إضافة إعلان جديد' : 'Create Listing';
  }

  Future<void> _submit() async {
    final capabilities = ref.read(accountCapabilitiesProvider);
    if (!capabilities.isActivatedSellerForSection(_slug)) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCityId == null) {
      setState(() {
        _errorMessage = 'Please select category and city / اختر القسم والمدينة';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      await ref.read(listingsRepositoryProvider).createListing(
            CreateListingDto(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              price: price,
              categoryId: _selectedCategoryId!,
              cityId: _selectedCityId!,
              mediaKeys: const [],
              attributes: {'listingKind': widget.listingKind},
            ),
          );
      ref.invalidate(sellerListingsControllerProvider(_slug));
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final capabilities = ref.watch(accountCapabilitiesProvider);
    final isAuthorized = capabilities.isActivatedSellerForSection(_slug);
    final hPad = context.horizontalScreenPadding;

    if (!isAuthorized) {
      return Scaffold(
        backgroundColor: DealOneTokens.pageBgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              DealOneSubPageHeader(
                title: _headerTitle(isArabic),
                showBackButton: Navigator.of(context).canPop(),
              ),
              Expanded(
                child: DealOneEmptyStateView(
                  icon: Icons.lock_outline_rounded,
                  title: isArabic ? 'غير مصرح بالإضافة' : 'Not Authorized',
                  description: isArabic
                      ? 'لا يملك حسابك صلاحية إضافة إعلانات أو خدمات في هذا القسم.'
                      : 'Your account does not have verified seller permission for this category.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final categoryAsync = ref.watch(categoryBySlugProvider(_slug));
    final govAsync = ref.watch(governoratesProvider);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: _headerTitle(isArabic),
              showBackButton: Navigator.of(context).canPop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: AppRadii.md,
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'العنوان' : 'Title',
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? (isArabic ? 'أدخل عنواناً واضحاً' : 'Enter a valid title')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'الوصف' : 'Description',
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? (isArabic ? 'أدخل وصفاً تفصيلياً' : 'Enter a detailed description')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isArabic ? 'السعر (جنيه مصري)' : 'Price (EGP)',
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n < 0) {
                          return isArabic ? 'أدخل سعراً صحيحاً' : 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    categoryAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (cat) {
                        final options = cat.subcategories.isNotEmpty
                            ? cat.subcategories
                            : [cat];
                        _selectedCategoryId ??= options.first.id;
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'التصنيف' : 'Subcategory',
                          ),
                          items: options
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(isArabic ? c.nameAr : c.nameEn),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategoryId = v),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    govAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (govs) {
                        final cities = govs.expand((g) => g.cities).toList();
                        if (cities.isEmpty) return const SizedBox.shrink();
                        _selectedCityId ??= cities.first.id;
                        return DropdownButtonFormField<int>(
                          initialValue: _selectedCityId,
                          decoration: InputDecoration(
                            labelText: isArabic ? 'المدينة' : 'City',
                          ),
                          items: cities
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(isArabic ? c.nameAr : c.nameEn),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCityId = v),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isArabic
                                  ? 'حفظ وإرسال للمراجعة'
                                  : 'Submit for Review',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
