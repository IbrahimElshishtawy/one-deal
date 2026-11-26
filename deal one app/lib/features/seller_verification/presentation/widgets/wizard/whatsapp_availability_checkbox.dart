import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent checkbox toggle (`هذا الرقم متاح للتواصل عبر واتساب`).
class WhatsappAvailabilityCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const WhatsappAvailabilityCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      key: const Key('wizard_whatsapp_checkbox'),
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? WizardTheme.primaryNavy(context)
                    : WizardTheme.cardBg(context),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? WizardTheme.primaryNavy(context)
                      : WizardTheme.dashedBorder(context),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isArabic
                    ? 'هذا الرقم متاح للتواصل عبر واتساب'
                    : 'This number is available on WhatsApp',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: WizardTheme.secondaryInk(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
