import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/widgets/account_avatar_widget.dart';
import 'package:market_space/core/navigation/drawer/widgets/account_info_widget.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/accounts/domain/entities/account_entity.dart';

/// Composes the Drawer's Account Header: avatar, account info, verification badge,
/// guest sign-in CTA, error/retry banner, and multi-account switcher chips.
class DrawerHeaderWidget extends StatelessWidget {
  final bool isArabic;
  final String? userName;
  final AccountCapabilities capabilities;
  final Object? accountsError;
  final VoidCallback onRetryAccounts;
  final ValueChanged<UserAccountEntity> onSwitchAccount;
  final VoidCallback onSignInTap;

  const DrawerHeaderWidget({
    super.key,
    required this.isArabic,
    required this.userName,
    required this.capabilities,
    required this.accountsError,
    required this.onRetryAccounts,
    required this.onSwitchAccount,
    required this.onSignInTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeAcc = capabilities.effectiveAccount;

    return Container(
      key: const Key('drawer_account_header'),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: DealOneTokens.navy,
        borderRadius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccountAvatarWidget(imageUrl: activeAcc?.logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: AccountInfoWidget(
                  userName: userName,
                  capabilities: capabilities,
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
          if (!capabilities.isAuthenticated) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('drawer_guest_signin_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: DealOneTokens.navy,
                ),
                onPressed: onSignInTap,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(isArabic ? 'تسجيل الدخول' : 'Sign In'),
              ),
            ),
          ],
          if (accountsError != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('drawer_accounts_error_banner'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D1D),
                borderRadius: AppRadii.md,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'تعذر تحميل صلاحيات الحساب'
                          : 'Failed to load account permissions',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5),
                    ),
                  ),
                  TextButton(
                    key: const Key('drawer_accounts_retry_btn'),
                    onPressed: onRetryAccounts,
                    child: Text(
                      isArabic ? 'إعادة' : 'Retry',
                      style: const TextStyle(color: Colors.amberAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (capabilities.isAuthenticated &&
              capabilities.accounts.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: capabilities.accounts.map((acc) {
                  final selected = acc.id == activeAcc?.id;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      key: Key('drawer_switch_account_${acc.id}'),
                      label: Text(
                        acc.displayName,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: selected ? DealOneTokens.navy : Colors.white,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      onSelected: (_) => onSwitchAccount(acc),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
