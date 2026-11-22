import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';

/// User summary card matching `Profile.png`:
/// Avatar + verified badge, bold user name, location pin, and "تعديل البيانات" CTA.
class ProfileUserCard extends StatelessWidget {
  final String fullName;
  final String locationLabel;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback onEditTap;

  const ProfileUserCard({
    super.key,
    required this.fullName,
    required this.locationLabel,
    required this.onEditTap,
    this.avatarUrl,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isCompact = context.isCompactPhone;

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      decoration: DealOneTokens.cardDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackButton = constraints.maxWidth < 300 ||
              context.effectiveTextScale >= 1.5;

          final identityRow = Row(
            children: [
              DealOneAvatar(
                imageUrl: avatarUrl,
                fallbackText: fullName,
                size: isCompact ? 52 : 60,
                isVerified: isVerified,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: DealOneTokens.textPrimaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: DealOneTokens.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final editButton = ElevatedButton(
            key: const Key('profile_edit_account_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DealOneTokens.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: 11,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
            ),
            onPressed: onEditTap,
            child: Text(
              isArabic ? 'تعديل البيانات' : 'Edit Profile',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          );

          if (stackButton) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identityRow,
                const SizedBox(height: AppSpacing.md),
                editButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identityRow),
              const SizedBox(width: AppSpacing.sm),
              editButton,
            ],
          );
        },
      ),
    );
  }
}
