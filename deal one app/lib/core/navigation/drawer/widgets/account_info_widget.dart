import 'package:flutter/material.dart';
import 'package:market_space/core/navigation/domain/account_capabilities.dart';
import 'package:market_space/core/navigation/drawer/widgets/account_verification_widget.dart';

/// Displays account name and verification status inside the Drawer header.
class AccountInfoWidget extends StatelessWidget {
  final String? userName;
  final AccountCapabilities capabilities;
  final bool isArabic;

  const AccountInfoWidget({
    super.key,
    required this.userName,
    required this.capabilities,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final activeAcc = capabilities.effectiveAccount;
    final displayTitle = capabilities.isAuthenticated
        ? (activeAcc?.displayName.isNotEmpty == true
            ? activeAcc!.displayName
            : (userName ?? (isArabic ? 'حسابي' : 'My Account')))
        : (isArabic ? 'زائر ديل ون' : 'Deal One Guest');

    return Column(
      key: const Key('drawer_account_info'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        AccountVerificationWidget(
          capabilities: capabilities,
          isArabic: isArabic,
        ),
      ],
    );
  }
}
