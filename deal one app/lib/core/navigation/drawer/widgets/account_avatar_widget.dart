import 'package:flutter/material.dart';

/// Displays the user's or business account's circular avatar inside the Drawer header.
class AccountAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const AccountAvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return CircleAvatar(
      key: const Key('drawer_account_avatar'),
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.16),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : const Icon(Icons.person_rounded, color: Colors.white),
    );
  }
}
