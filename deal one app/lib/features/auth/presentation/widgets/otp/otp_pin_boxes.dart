import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/validators/auth_validators.dart';
import '../../theme/auth_design_tokens.dart';

/// 6-digit left-to-right OTP entry strip matching `otp.png` and
/// `لو المستخدم دخل الرمز غلط.png` with amber focus, vertical cursor bar,
/// red error borders, paste support, and SMS-autofill.
class OtpPinBoxes extends StatefulWidget {
  final String code;
  final int length;
  final bool hasError;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const OtpPinBoxes({
    super.key,
    required this.code,
    this.length = OtpCodeValidator.requiredLength,
    this.hasError = false,
    this.enabled = true,
    this.focusNode,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpPinBoxes> createState() => _OtpPinBoxesState();
}

class _OtpPinBoxesState extends State<OtpPinBoxes> {
  late final TextEditingController _controller;
  FocusNode? _ownedFocusNode;
  bool _hasFocus = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant OtpPinBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _ownedFocusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null && _ownedFocusNode == null) {
        _ownedFocusNode = FocusNode();
      }
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
    if (widget.code != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.code,
        selection: TextSelection.collapsed(offset: widget.code.length),
      );
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _hasFocus = _effectiveFocusNode.hasFocus);
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
    return Semantics(
      label: 'حقل إدخال رمز التحقق المكون من ${widget.length} أرقام',
      textField: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled
              ? () => _effectiveFocusNode.requestFocus()
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.0,
                  child: TextField(
                    key: const Key('otp_hidden_input'),
                    controller: _controller,
                    focusNode: _effectiveFocusNode,
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
                    final boxHeight = (boxWidth * 1.18).clamp(52.0, 64.0);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.length, (index) {
                        final digit = index < widget.code.length
                            ? widget.code[index]
                            : '';
                        final isActiveCell =
                            widget.enabled &&
                            !widget.hasError &&
                            ((_hasFocus && index == widget.code.length) ||
                                (widget.code.isEmpty && index == 0) ||
                                (_hasFocus &&
                                    widget.code.length == widget.length &&
                                    index == widget.length - 1));

                        final borderColor = widget.hasError
                            ? AuthDesignTokens.errorRed
                            : (isActiveCell
                                  ? AuthDesignTokens.focusOrange
                                  : (digit.isNotEmpty
                                        ? AuthDesignTokens.navyPrimary
                                              .withValues(alpha: 0.45)
                                        : AuthDesignTokens.borderOf(context)));

                        final fillColor = AuthDesignTokens.surfaceOf(context);

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
                                    ? 1.7
                                    : 1.0,
                              ),
                              boxShadow: AuthDesignTokens.cardShadowOf(context),
                            ),
                            child: digit.isNotEmpty
                                ? Text(
                                    digit,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: AuthDesignTokens.headingOf(
                                        context,
                                      ),
                                    ),
                                  )
                                : (isActiveCell
                                      ? Container(
                                          width: 2,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: AuthDesignTokens.focusOrange,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink()),
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
      ),
    );
  }
}
