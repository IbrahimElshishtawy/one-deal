import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/app_localization.dart';
import '../../theme/auth_design_tokens.dart';
import '../common/auth_brand_icons.dart';
import '../common/auth_country_prefix.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Modular Sign Up form card matching `Sign-Up.png`.
class SignUpFormCard extends StatefulWidget {
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String? fullNameError;
  final String? phoneError;
  final String? submitError;
  final bool isSubmitting;
  final ValueChanged<String> onFullNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSubmit;

  const SignUpFormCard({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    this.fullNameError,
    this.phoneError,
    this.submitError,
    required this.isSubmitting,
    required this.onFullNameChanged,
    required this.onPhoneChanged,
    required this.onSubmit,
  });

  @override
  State<SignUpFormCard> createState() => _SignUpFormCardState();
}

class _SignUpFormCardState extends State<SignUpFormCard> {
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.submitError != null && widget.submitError!.isNotEmpty) ...[
          AuthErrorBanner(message: widget.submitError!),
          const SizedBox(height: AuthDesignTokens.spaceBase),
        ],
        AuthTextField(
          key: const Key('signup_fullname_field'),
          hintText: l10n.signUpFullNameHint,
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
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩+\s\-]')),
            LengthLimitingTextInputFormatter(16),
          ],
          enabled: !widget.isSubmitting,
          onChanged: widget.onPhoneChanged,
          onSubmitted: (_) => widget.onSubmit(),
        ),
        const SizedBox(height: AuthDesignTokens.spaceSm),
        Text(
          l10n.signUpWhatsAppHelper,
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
