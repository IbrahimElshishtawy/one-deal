import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/theme/app_radii.dart';

/// Displays the authoritative account verification & type badge inside the Drawer header.
class AccountVerificationWidget extends StatelessWidget {
  final AccountCapabilities capabilities;
  final bool isArabic;

  const AccountVerificationWidget({
    super.key,
    required this.capabilities,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final activeAcc = capabilities.effectiveAccount;
    final bool isVerified = activeAcc?.isVerified == true;

    final String label = !capabilities.isAuthenticated
        ? (isArabic ? 'غير مسجّل' : 'Guest')
        : capabilities.isLoading
            ? (isArabic ? 'جارٍ التحقق...' : 'Verifying...')
            : activeAcc == null
                ? (isArabic ? 'مشتري' : 'Buyer')
                : isVerified
                    ? '${activeAcc.accountType} • ${isArabic ? 'موثّق' : 'Verified'}'
                    : '${activeAcc.accountType} • ${activeAcc.verificationStatus}';

    return Container(
      key: const Key('drawer_account_verification_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFF16A34A).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified) ...[
            const Icon(
              Icons.verified_rounded,
              size: 12,
              color: Color(0xFF86EFAC),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
