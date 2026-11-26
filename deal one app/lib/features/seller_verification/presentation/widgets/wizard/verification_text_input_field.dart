import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent, Light/Dark adaptive rounded input card matching both wizard
/// steps (label with `*` or `اختياري` badge, soft shadow card, optional icon,
/// optional helper caption, and inline validation feedback).
class VerificationTextInputField extends StatefulWidget {
  final Key? fieldKey;
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final bool isRequired;
  final String? optionalLabel;
  final String? errorText;
  final String? helperText;
  final String? helperStatusText;
  final bool helperStatusValid;
  final IconData? trailingIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int minLines;
  final int? maxLength;

  const VerificationTextInputField({
    super.key,
    this.fieldKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.isRequired = true,
    this.optionalLabel,
    this.errorText,
    this.helperText,
    this.helperStatusText,
    this.helperStatusValid = false,
    this.trailingIcon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines = 1,
    this.maxLength,
  });

  @override
  State<VerificationTextInputField> createState() =>
      _VerificationTextInputFieldState();
}

class _VerificationTextInputFieldState
    extends State<VerificationTextInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant VerificationTextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final optText = widget.optionalLabel ?? (isArabic ? 'اختياري' : 'Optional');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: WizardTheme.primaryInk(context),
                  ),
                  children: [
                    TextSpan(text: widget.label),
                    if (widget.isRequired)
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
            ),
            if (!widget.isRequired)
              Text(
                optText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: WizardTheme.secondaryInk(context),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: WizardTheme.cardBg(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? WizardTheme.danger(context)
                  : WizardTheme.border(context),
              width: hasError ? 1.4 : 1.0,
            ),
            boxShadow: WizardTheme.inputShadow(context),
          ),
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: WizardTheme.primaryInk(context),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: WizardTheme.hintInk(context),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.maxLines > 1 ? 14 : 15,
              ),
              prefixIcon: widget.trailingIcon != null
                  ? Icon(
                      widget.trailingIcon,
                      size: 20,
                      color: WizardTheme.secondaryInk(context),
                    )
                  : null,
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
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WizardTheme.danger(context),
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null || widget.helperStatusText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (widget.helperText != null)
                Expanded(
                  child: Text(
                    widget.helperText!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: WizardTheme.secondaryInk(context),
                    ),
                  ),
                ),
              if (widget.helperStatusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.helperStatusValid
                        ? WizardTheme.successSoft(context)
                        : WizardTheme.softBlueBg(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.helperStatusText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.helperStatusValid
                          ? WizardTheme.success(context)
                          : WizardTheme.secondaryInk(context),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
