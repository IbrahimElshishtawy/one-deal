import 'package:flutter/material.dart';

import 'package:market_space/app/app_localization.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/activity_hub/domain/entities/cart_item_entity.dart';
import 'package:market_space/features/activity_hub/presentation/utils/activity_hub_l10n.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_item_image.dart';
import 'package:market_space/features/activity_hub/presentation/widgets/cart/cart_quantity_selector.dart';

class CartItemCard extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onSaveForLater;
  final bool isMutating;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onSaveForLater,
    this.isMutating = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: AppRadii.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.lg,
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CartItemImage(imageUrl: item.imageUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.cartSellerLabel(item.sellerName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        if (item.selectedSize != null ||
                            item.selectedColor != null) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (item.selectedSize != null &&
                                  item.selectedSize!.isNotEmpty)
                                _VariantChip(
                                  label: l10n.cartSizeLabel(item.selectedSize!),
                                ),
                              if (item.selectedColor != null &&
                                  item.selectedColor!.isNotEmpty)
                                _VariantChip(
                                  label: l10n.cartColorLabel(
                                    item.selectedColor!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                ActivityHubL10n.formatPrice(
                                  item.unitPrice,
                                  currency: item.currency,
                                  isArabic: isArabic,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: DealOneDesignColors.amberPrice,
                                ),
                              ),
                            ),
                            CartQuantitySelector(
                              quantity: item.quantity,
                              isDisabled: isMutating,
                              onIncrement: onIncrement,
                              onDecrement: onDecrement,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: isMutating ? null : onSaveForLater,
                    icon: const Icon(Icons.bookmark_border_rounded, size: 17),
                    label: Text(l10n.cartSaveForLater),
                  ),
                  TextButton.icon(
                    onPressed: isMutating ? null : onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorOf(context),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: Text(l10n.cartRemoveItem),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  final String label;

  const _VariantChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }
}
