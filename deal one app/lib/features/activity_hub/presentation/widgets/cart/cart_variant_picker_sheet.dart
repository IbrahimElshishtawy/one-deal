import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/application/providers/cart_provider.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_quantity_selector.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/shared/activity_action_button.dart';
import 'package:market_space/features/listings/domain/entities/listing_entity.dart';

/// Bottom sheet allowing users to pick size, color, and quantity before adding
/// a product (especially Fashion & Accessories or Building Materials) to the cart.
class CartVariantPickerSheet extends ConsumerStatefulWidget {
  final ListingItem listing;
  final bool requireSizeAndColor;

  const CartVariantPickerSheet({
    super.key,
    required this.listing,
    this.requireSizeAndColor = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ListingItem listing,
    bool requireSizeAndColor = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartVariantPickerSheet(
        listing: listing,
        requireSizeAndColor: requireSizeAndColor,
      ),
    );
  }

  @override
  ConsumerState<CartVariantPickerSheet> createState() =>
      _CartVariantPickerSheetState();
}

class _CartVariantPickerSheetState
    extends ConsumerState<CartVariantPickerSheet> {
  static const List<String> _defaultSizes = ['S', 'M', 'L', 'XL'];
  static const List<String> _defaultColorsEn = [
    'Black',
    'White',
    'Navy',
    'Beige',
  ];
  static const List<String> _defaultColorsAr = [
    'أسود',
    'أبيض',
    'كحلي',
    'بيج',
  ];

  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final attrSize = widget.listing.attributes['size']?.toString();
    final attrColor = widget.listing.attributes['color']?.toString();
    if (widget.requireSizeAndColor) {
      _selectedSize = (attrSize != null && attrSize.isNotEmpty)
          ? attrSize
          : _defaultSizes[1];
      _selectedColor = (attrColor != null && attrColor.isNotEmpty)
          ? attrColor
          : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final colorsList = isArabic ? _defaultColorsAr : _defaultColorsEn;
    final activeColor = _selectedColor ?? colorsList.first;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cartSelectVariantTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMutedOf(context)),
            ),
            if (widget.requireSizeAndColor) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.cartSelectSize,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: _defaultSizes.map((size) {
                  final selected = _selectedSize == size;
                  return ChoiceChip(
                    label: Text(size),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSize = size),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.cartSelectColor,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: colorsList.map((color) {
                  final selected = activeColor == color;
                  return ChoiceChip(
                    label: Text(color),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedColor = color),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.cartQuantityLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                CartQuantitySelector(
                  quantity: _quantity,
                  onIncrement: () => setState(() => _quantity++),
                  onDecrement: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ActivityActionButton(
                label: l10n.cartAddToCartAction,
                icon: Icons.shopping_basket_rounded,
                onPressed: () async {
                  final added = await ref
                      .read(cartProvider.notifier)
                      .addListingToCart(
                        widget.listing,
                        quantity: _quantity,
                        selectedSize: widget.requireSizeAndColor
                            ? _selectedSize
                            : null,
                        selectedColor: widget.requireSizeAndColor
                            ? activeColor
                            : null,
                      );
                  if (context.mounted) {
                    Navigator.pop(context, added);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
