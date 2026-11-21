import 'package:flutter/material.dart';

import 'package:market_space/shared/widgets/app_network_image.dart';

/// Legacy SafeNetworkImage component, now fully powered by the unified
/// professional [AppNetworkImage] system.
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      fallbackIcon: fallbackIcon,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
