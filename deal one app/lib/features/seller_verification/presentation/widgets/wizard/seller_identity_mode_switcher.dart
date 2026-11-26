import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent segmented toggle matching Screenshot 2:
/// - `فرد / مسوق مستقل` (`SellerType.individual`)
/// - `شركة / مكتب عقاري` (`SellerType.business`)
class SellerIdentityModeSwitcher extends StatelessWidget {
  final SellerType selectedMode;
  final ValueChanged<SellerType> onChanged;

  const SellerIdentityModeSwitcher({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isIndividual = selectedMode != SellerType.business;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: WizardTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WizardTheme.border(context)),
        boxShadow: WizardTheme.inputShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: const Key('identity_mode_individual'),
              label: isArabic ? 'فرد / مسوق مستقل' : 'Individual',
              icon: Icons.person_outline_rounded,
              isActive: isIndividual,
              onTap: () => onChanged(SellerType.individual),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              key: const Key('identity_mode_business'),
              label: isArabic ? 'شركة / مكتب عقاري' : 'Company / Office',
              icon: Icons.apartment_rounded,
              isActive: !isIndividual,
              onTap: () => onChanged(SellerType.business),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = WizardTheme.primaryButtonBg(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : WizardTheme.secondaryInk(context),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : WizardTheme.secondaryInk(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
