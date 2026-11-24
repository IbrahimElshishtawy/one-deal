import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_spacing.dart';

/// Independent trust & encryption footer displayed at the bottom of the inbox.
class InboxPrivacyFooter extends StatelessWidget {
  const InboxPrivacyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      key: const Key('inbox_privacy_footer'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        96,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DealOneTokens.softTileBgOf(context),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isArabic
                ? 'محادثاتك مشفرة ومحمية بالكامل'
                : 'Your chats are encrypted and protected',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DealOneTokens.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isArabic
                ? 'جميع المعاملات تتم تحت إشراف مستشارين معتمدين'
                : 'All conversations are protected by Deal One safety standards',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: DealOneTokens.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
