import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';

/// Independent unauthenticated sign-in gate displayed in the inbox for guests.
class InboxGuestGate extends StatelessWidget {
  final VoidCallback onSignIn;

  const InboxGuestGate({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      key: const Key('inbox_guest_gate'),
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: isArabic ? 'المحادثات' : 'Conversations',
            ),
            Expanded(
              child: DealOneEmptyStateView(
                icon: Icons.chat_bubble_outline_rounded,
                title: isArabic
                    ? 'سجّل الدخول لعرض محادثاتك'
                    : 'Sign in to view your chats',
                description: isArabic
                    ? 'تواصل مباشرة مع المعلنين ومستشاري العقارات بعد تسجيل الدخول.'
                    : 'Sign in to chat directly with property owners and Deal One advisors.',
                actionLabel: isArabic ? 'تسجيل الدخول' : 'Sign In',
                actionIcon: Icons.login_rounded,
                onAction: onSignIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
