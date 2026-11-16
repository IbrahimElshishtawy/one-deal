import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_design_tokens.dart';
import '../common/auth_brand_icons.dart';
import '../common/auth_country_prefix.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Modular Sign Up form card matching `ui/انشاء حساب.png`.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.submitError != null && widget.submitError!.isNotEmpty) ...[
          AuthErrorBanner(message: widget.submitError!),
          const SizedBox(height: 14),
        ],
        AuthTextField(
          key: const Key('signup_fullname_field'),
          hintText: 'اكتب اسمك هنا',
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
        const SizedBox(height: 14),
        AuthTextField(
          key: const Key('signup_phone_field'),
          hintText: '01XXXXXXXXX',
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
          textAlign: TextAlign.right,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩+\s\-]')),
            LengthLimitingTextInputFormatter(16),
          ],
          enabled: !widget.isSubmitting,
          onChanged: widget.onPhoneChanged,
          onSubmitted: (_) => widget.onSubmit(),
        ),
        const SizedBox(height: 8),
        Text(
          'سيتم إرسال رمز التحقق عبر الواتساب',
          style: TextStyle(
            fontSize: 12,
            color: AuthDesignTokens.mutedOf(context),
          ),
        ),
        const SizedBox(height: 20),
        AuthPrimaryButton(
          key: const Key('signup_submit_button'),
          label: 'إرسال رمز التحقق',
          isLoading: widget.isSubmitting,
          onPressed: widget.onSubmit,
        ),
      ],
    );
  }
}
