import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_design_tokens.dart';
import '../common/auth_country_prefix.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Modular Sign Up form card containing full name, Egyptian mobile number,
/// legal agreement notice, and verification code submission button.
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
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

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
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  State<SignUpFormCard> createState() => _SignUpFormCardState();
}

class _SignUpFormCardState extends State<SignUpFormCard> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void didUpdateWidget(covariant SignUpFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _termsRecognizer.onTap = widget.onTermsTap;
    _privacyRecognizer.onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
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
          const SizedBox(height: 16),
        ],
        AuthTextField(
          key: const Key('signup_fullname_field'),
          label: 'الاسم الكامل',
          hintText: 'مثال: أحمد محمد علي',
          controller: widget.fullNameController,
          errorText: widget.fullNameError,
          leadingIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          enabled: !widget.isSubmitting,
          onChanged: widget.onFullNameChanged,
          onSubmitted: (_) => _phoneFocusNode.requestFocus(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          key: const Key('signup_phone_field'),
          label: 'رقم الهاتف',
          hintText: '010 1234 5678',
          controller: widget.phoneController,
          focusNode: _phoneFocusNode,
          errorText: widget.phoneError,
          leadingIcon: Icons.phone_android_rounded,
          prefixBadge: const AuthCountryPrefixBadge(),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩+\s\-]')),
            LengthLimitingTextInputFormatter(16),
          ],
          enabled: !widget.isSubmitting,
          onChanged: widget.onPhoneChanged,
          onSubmitted: (_) => widget.onSubmit(),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: AuthDesignTokens.mutedOf(context),
            ),
            children: [
              const TextSpan(text: 'بإنشائك للحساب فإنك توافق على '),
              TextSpan(
                text: 'شروط الاستخدام',
                recognizer: _termsRecognizer,
                style: const TextStyle(
                  color: AuthDesignTokens.actionBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: ' و '),
              TextSpan(
                text: 'سياسة الخصوصية',
                recognizer: _privacyRecognizer,
                style: const TextStyle(
                  color: AuthDesignTokens.actionBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
