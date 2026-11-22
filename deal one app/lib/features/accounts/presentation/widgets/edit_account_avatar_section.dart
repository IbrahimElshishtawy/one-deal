import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Centered avatar picker header matching `Edit account details.png`.
class EditAccountAvatarSection extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  final VoidCallback onChangeAvatarTap;

  const EditAccountAvatarSection({
    super.key,
    required this.fullName,
    required this.onChangeAvatarTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DealOneAvatar(
          imageUrl: avatarUrl,
          fallbackText: fullName,
          size: 96,
          onTap: onChangeAvatarTap,
          badge: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DealOneTokens.navy,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: onChangeAvatarTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 18,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isArabic ? 'تغيير الصورة الشخصية' : 'Change Profile Photo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DealOneTokens.textPrimaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isArabic
              ? 'الحد الأقصى 5 ميجابايت (JPG, PNG)'
              : 'Max size 5 MB (JPG, PNG)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}
