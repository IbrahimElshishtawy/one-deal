import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent pill badge (`حساب شركاء الأعمال`) displayed above Step 1 header.
class PartnerAccountBadgePill extends StatelessWidget {
  final String? text;

  const PartnerAccountBadgePill({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final label =
        text ?? (isArabic ? 'حساب شركاء الأعمال' : 'Business Partners Account');

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: WizardTheme.softBlueBg(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: WizardTheme.softBlueBorder(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 16,
              color: WizardTheme.primaryInk(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: WizardTheme.primaryInk(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
