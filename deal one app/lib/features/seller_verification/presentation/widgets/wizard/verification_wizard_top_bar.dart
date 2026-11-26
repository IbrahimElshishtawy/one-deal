import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent top bar matching the design:
/// - Back arrow button on start edge
/// - `• خطوة X من Y` badge + animated segmented progress bar on end edge
class VerificationWizardTopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const VerificationWizardTopBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    final label = isArabic
        ? 'خطوة $currentStep من $totalSteps'
        : 'Step $currentStep of $totalSteps';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            key: const Key('wizard_back_button'),
            onPressed: onBack,
            tooltip: isArabic ? 'رجوع' : 'Back',
            icon: Icon(
              Icons.arrow_back_rounded,
              color: WizardTheme.primaryInk(context),
              size: 24,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: WizardTheme.primaryInk(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    key: const Key('wizard_step_label'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: WizardTheme.primaryInk(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 96,
                height: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: WizardTheme.progressTrack(context)),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: progress),
                        builder: (context, value, _) {
                          return FractionallySizedBox(
                            alignment: AlignmentDirectional.centerEnd,
                            widthFactor: value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: WizardTheme.primaryInk(context),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
