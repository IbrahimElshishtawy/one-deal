import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/validators/auth_validators.dart';
import '../../theme/auth_design_tokens.dart';

/// 6-digit left-to-right OTP entry strip with distinct default, orange focus,
/// and red error/expired visual states plus paste & SMS-autofill support.
class OtpPinBoxes extends StatefulWidget {
  final String code;
  final int length;
  final bool hasError;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const OtpPinBoxes({
    super.key,
    required this.code,
    this.length = OtpCodeValidator.requiredLength,
    this.hasError = false,
    this.enabled = true,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpPinBoxes> createState() => _OtpPinBoxesState();
}

class _OtpPinBoxesState extends State<OtpPinBoxes> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant OtpPinBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  void _handleTextChanged(String raw) {
    final normalized = OtpCodeValidator.normalizeDigits(raw);
    final clipped = normalized.length > widget.length
        ? normalized.substring(0, widget.length)
        : normalized;

    if (clipped != _controller.text) {
      _controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    }

    widget.onChanged(clipped);
    if (clipped.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden functional TextField handling keyboard, paste, and SMS autofill.
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  key: const Key('otp_hidden_input'),
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _handleTextChanged,
                  onSubmitted: (_) => widget.onCompleted?.call(),
                ),
              ),
            ),
            IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final totalSpacing = spacing * (widget.length - 1);
                  final boxWidth =
                      ((constraints.maxWidth - totalSpacing) / widget.length)
                          .clamp(42.0, 56.0);
                  final boxHeight = (boxWidth * 1.16).clamp(52.0, 62.0);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.length, (index) {
                      final digit = index < widget.code.length
                          ? widget.code[index]
                          : '';
                      final isActiveCell =
                          _hasFocus &&
                          ((index == widget.code.length) ||
                              (widget.code.length == widget.length &&
                                  index == widget.length - 1));

                      final borderColor = widget.hasError
                          ? AuthDesignTokens.errorRed
                          : (isActiveCell
                                ? AuthDesignTokens.focusOrange
                                : (digit.isNotEmpty
                                      ? AuthDesignTokens.navyPrimary
                                      : AuthDesignTokens.borderOf(context)));

                      final fillColor = widget.hasError
                          ? AuthDesignTokens.errorTintOf(context)
                          : (isActiveCell
                                ? AuthDesignTokens.focusOrangeTint.withValues(
                                    alpha: AuthDesignTokens.isDark(context)
                                        ? 0.16
                                        : 0.7,
                                  )
                                : AuthDesignTokens.inputFillOf(context));

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == widget.length - 1 ? 0 : spacing,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          width: boxWidth,
                          height: boxHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(
                              AuthDesignTokens.otpBoxRadius,
                            ),
                            border: Border.all(
                              color: borderColor,
                              width: (widget.hasError || isActiveCell)
                                  ? 1.8
                                  : 1.2,
                            ),
                          ),
                          child: Text(
                            digit,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: widget.hasError
                                  ? AuthDesignTokens.errorRed
                                  : AuthDesignTokens.headingOf(context),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
