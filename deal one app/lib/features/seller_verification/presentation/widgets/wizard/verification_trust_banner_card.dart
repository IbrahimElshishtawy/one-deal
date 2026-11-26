import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent soft blue-tinted trust & verification reassurance card.
/// Reused in Step 1 (`ضمان توثيق الحسابات`) and Step 2 (`حماية وضمان الصفقة الأولى`).
class VerificationTrustBannerCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const VerificationTrustBannerCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.verified_user_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: WizardTheme.softBlueBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WizardTheme.softBlueBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: WizardTheme.softBlueCircleBg(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: WizardTheme.primaryInk(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: WizardTheme.primaryInk(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: WizardTheme.secondaryInk(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
