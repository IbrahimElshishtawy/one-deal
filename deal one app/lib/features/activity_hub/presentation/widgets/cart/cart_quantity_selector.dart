import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';

class CartQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final bool isDisabled;

  const CartQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = !isDisabled && quantity > 1 && onDecrement != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryOf(context),
        borderRadius: AppRadii.full,
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: canDecrement ? onDecrement : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: isDisabled ? null : onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.full,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 16,
          color: onTap == null
              ? AppColors.disabledOf(context)
              : AppColors.textPrimaryOf(context),
        ),
      ),
    );
  }
}
