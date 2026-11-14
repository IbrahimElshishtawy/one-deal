import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/auth_country_prefix.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Modular Login form containing Egyptian mobile number entry and OTP dispatch button.
class LoginFormCard extends StatelessWidget {
  final TextEditingController phoneController;
  final String? phoneError;
  final String? submitError;
  final bool isSubmitting;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSubmit;

  const LoginFormCard({
    super.key,
    required this.phoneController,
    this.phoneError,
    this.submitError,
    required this.isSubmitting,
    required this.onPhoneChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (submitError != null && submitError!.isNotEmpty) ...[
          AuthErrorBanner(message: submitError!),
          const SizedBox(height: 16),
        ],
        AuthTextField(
          key: const Key('login_phone_field'),
          label: 'رقم الهاتف',
          hintText: '010 1234 5678',
          controller: phoneController,
          errorText: phoneError,
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
          enabled: !isSubmitting,
          onChanged: onPhoneChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 22),
        AuthPrimaryButton(
          key: const Key('login_submit_button'),
          label: 'تسجيل الدخول',
          isLoading: isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
