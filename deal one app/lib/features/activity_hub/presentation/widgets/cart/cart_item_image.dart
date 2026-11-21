import 'package:flutter/material.dart';

import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/shared/widgets/market_widgets/safe_network_image.dart';

class CartItemImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const CartItemImage({super.key, this.imageUrl, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.md,
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? SafeNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fallbackIcon: Icons.shopping_bag_outlined,
              )
            : Container(
                color: AppColors.surfaceSecondaryOf(context),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textMutedOf(context),
                  size: 28,
                ),
              ),
      ),
    );
  }
}
