import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_brand_icons.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_country_prefix.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_error_banner.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_primary_button.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_text_field.dart';

/// Modular Sign Up form card matching `Sign-Up.png`.
class SignUpFormCard extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController? emailController;
  final String? fullNameError;
  final String? phoneError;
  final String? emailError;
  final String? submitError;
  final bool isSubmitting;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String>? onEmailChanged;
  final VoidCallback onSubmit;

  const SignUpFormCard({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    this.emailController,
    this.fullNameError,
    this.phoneError,
    this.emailError,
    this.submitError,
    required this.isSubmitting,
    required this.onFullNameChanged,
    required this.onPhoneChanged,
    this.onEmailChanged,
    required this.onSubmit,
  });

  @override
  State<SignUpFormCard> createState() => _SignUpFormCardState();
}

class _SignUpFormCardState extends State<SignUpFormCard> {
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final phoneAlign = context.isRtl ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.submitError != null && widget.submitError!.isNotEmpty) ...[
          AuthErrorBanner(message: widget.submitError!),
          const SizedBox(height: AuthDesignTokens.spaceBase),
        ],
        AuthTextField(
          key: const Key('signup_fullname_field'),
          hintText: l10n.signUpNameHint,
          controller: widget.fullNameController,
          errorText: widget.fullNameError,
          leadingIcon: Icons.person_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          enabled: !widget.isSubmitting,
          onChanged: widget.onFullNameChanged,
          onSubmitted: (_) => _phoneFocusNode.requestFocus(),
        ),
        const SizedBox(height: AuthDesignTokens.spaceMd),
        AuthTextField(
          key: const Key('signup_phone_field'),
          hintText: l10n.signUpPhoneHint,
          controller: widget.phoneController,
          focusNode: _phoneFocusNode,
          errorText: widget.phoneError,
          leadingWidget: WhatsAppGlyphIcon(
            size: 20,
            color: widget.phoneError != null
                ? AuthDesignTokens.errorRed
                : AuthDesignTokens.mutedOf(context),
          ),
          trailingWidget: const AuthCountryPrefixBadge(compact: true),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          textAlign: phoneAlign,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩+\s\-]')),
            LengthLimitingTextInputFormatter(16),
          ],
          enabled: !widget.isSubmitting,
          onChanged: widget.onPhoneChanged,
          onSubmitted: (_) => widget.emailController != null
              ? _emailFocusNode.requestFocus()
              : widget.onSubmit(),
        ),
        if (widget.emailController != null) ...[
          const SizedBox(height: AuthDesignTokens.spaceMd),
          AuthTextField(
            key: const Key('signup_email_field'),
            hintText: context.isRtl
                ? 'البريد الإلكتروني (اختياري للتحقق)'
                : 'Email address (optional for verification)',
            controller: widget.emailController!,
            focusNode: _emailFocusNode,
            errorText: widget.emailError,
            leadingIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            textAlign: phoneAlign,
            autofillHints: const [AutofillHints.email],
            enabled: !widget.isSubmitting,
            onChanged: widget.onEmailChanged ?? (_) {},
            onSubmitted: (_) => widget.onSubmit(),
          ),
        ],
        const SizedBox(height: AuthDesignTokens.spaceSm),
        Text(
          l10n.signUpWhatsappNote,
          style: TextStyle(
            fontSize: 12,
            color: AuthDesignTokens.mutedOf(context),
          ),
        ),
        const SizedBox(height: AuthDesignTokens.spaceLg),
        AuthPrimaryButton(
          key: const Key('signup_submit_button'),
          label: l10n.signUpSubmitButton,
          isLoading: widget.isSubmitting,
          onPressed: widget.onSubmit,
        ),
      ],
    );
  }
}
