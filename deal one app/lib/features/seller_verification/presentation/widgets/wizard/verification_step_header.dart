import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent step title + optional seal icon + descriptive subtitle widget.
class VerificationStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? titleIcon;

  const VerificationStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: WizardTheme.primaryInk(context),
                ),
              ),
            ),
            if (titleIcon != null) ...[
              const SizedBox(width: 8),
              Icon(
                titleIcon,
                size: 22,
                color: WizardTheme.primaryInk(context),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: WizardTheme.secondaryInk(context),
          ),
        ),
      ],
    );
  }
}
