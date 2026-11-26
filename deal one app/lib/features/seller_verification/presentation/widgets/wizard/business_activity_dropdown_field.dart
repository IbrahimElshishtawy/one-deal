import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/domain/algorithms/seller_verification_algorithms.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent dropdown selector card for choosing the seller's real-estate activity.
class BusinessActivityDropdownField extends StatelessWidget {
  final String? selectedCode;
  final String? errorText;
  final ValueChanged<SellerActivityOption> onSelected;

  const BusinessActivityDropdownField({
    super.key,
    required this.selectedCode,
    this.errorText,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final selected =
        SellerVerificationAlgorithms.findActivityByCode(selectedCode);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: WizardTheme.primaryInk(context),
            ),
            children: [
              TextSpan(
                text: isArabic
                    ? 'نوع النشاط العقاري'
                    : 'Real Estate Activity Type',
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: hasError
                      ? WizardTheme.danger(context)
                      : WizardTheme.primaryInk(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: WizardTheme.cardBg(context),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: const Key('wizard_activity_selector'),
            onTap: () => _openActivityPicker(context, isArabic),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasError
                      ? WizardTheme.danger(context)
                      : WizardTheme.border(context),
                  width: hasError ? 1.4 : 1.0,
                ),
                boxShadow: WizardTheme.inputShadow(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selected != null
                          ? selected.localizedTitle(isArabic)
                          : (isArabic
                              ? 'اختر نوع النشاط (تسويق عقاري، مطور عقاري...)'
                              : 'Select activity (Real estate marketing, developer...)'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected != null ? FontWeight.w700 : FontWeight.w400,
                        color: selected != null
                            ? WizardTheme.primaryInk(context)
                            : WizardTheme.hintInk(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: WizardTheme.secondaryInk(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: WizardTheme.danger(context),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WizardTheme.danger(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openActivityPicker(BuildContext context, bool isArabic) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WizardTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WizardTheme.border(sheetCtx),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isArabic
                      ? 'اختر نوع النشاط العقاري'
                      : 'Select Real Estate Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WizardTheme.primaryInk(sheetCtx),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount:
                        SellerVerificationAlgorithms.realEstateActivities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final opt = SellerVerificationAlgorithms
                          .realEstateActivities[index];
                      final isSelected = opt.code == selectedCode;
                      return InkWell(
                        key: Key('activity_option_${opt.code}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          onSelected(opt);
                          Navigator.of(sheetCtx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? WizardTheme.softBlueBg(sheetCtx)
                                : WizardTheme.elevatedCardBg(sheetCtx),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? WizardTheme.primaryNavy(sheetCtx)
                                  : WizardTheme.border(sheetCtx),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: WizardTheme.softBlueCircleBg(sheetCtx),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  opt.icon,
                                  color: WizardTheme.primaryInk(sheetCtx),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opt.localizedTitle(isArabic),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            WizardTheme.primaryInk(sheetCtx),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.localizedSubtitle(isArabic),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: WizardTheme.secondaryInk(
                                          sheetCtx,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: WizardTheme.primaryNavy(sheetCtx),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
