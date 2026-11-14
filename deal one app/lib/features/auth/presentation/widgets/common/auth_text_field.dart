import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_design_tokens.dart';

/// Auth text input featuring orange focus state, soft red error tint,
/// and optional country prefix badge for Egyptian phone entry.
class AuthTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? errorText;
  final IconData? leadingIcon;
  final Widget? prefixBadge;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.errorText,
    this.leadingIcon,
    this.prefixBadge,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textDirection,
    this.inputFormatters,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  FocusNode? _internalFocusNode;
  bool _hasFocus = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _internalFocusNode?.removeListener(_onFocusChanged);
      if (widget.focusNode == null && _internalFocusNode == null) {
        _internalFocusNode = FocusNode();
      }
      _effectiveFocusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _hasFocus = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final fillColor = hasError
        ? AuthDesignTokens.errorTintOf(context)
        : AuthDesignTokens.inputFillOf(context);
    final activeColor = hasError
        ? AuthDesignTokens.errorRed
        : (_hasFocus
              ? AuthDesignTokens.focusOrange
              : AuthDesignTokens.borderOf(context));
    final iconColor = hasError
        ? AuthDesignTokens.errorRed
        : (_hasFocus
              ? AuthDesignTokens.focusOrange
              : AuthDesignTokens.mutedOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AuthDesignTokens.headingOf(context),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(AuthDesignTokens.inputRadius),
            border: Border.all(
              color: activeColor,
              width: _hasFocus || hasError ? 1.7 : 1.1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, size: 20, color: iconColor),
                const SizedBox(width: 8),
              ],
              if (widget.prefixBadge != null) ...[
                widget.prefixBadge!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveFocusNode,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textDirection: widget.textDirection,
                  inputFormatters: widget.inputFormatters,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AuthDesignTokens.headingOf(context),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 14.5,
                      color: AuthDesignTokens.mutedOf(context)
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: AuthDesignTokens.errorRed,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AuthDesignTokens.errorRed,
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
