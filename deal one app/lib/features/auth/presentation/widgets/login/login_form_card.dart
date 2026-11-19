import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/app_localization.dart';
import '../../theme/auth_design_tokens.dart';
import '../common/auth_brand_icons.dart';
import '../common/auth_country_prefix.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Modular Login form matching `Log-in.png` with Egyptian mobile validation,
/// WhatsApp icon, default `+20` prefix indicator, and dark navy CTA.
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
    final l10n = AppLocalization.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (submitError != null && submitError!.isNotEmpty) ...[
          AuthErrorBanner(message: submitError!),
          const SizedBox(height: AuthDesignTokens.spaceBase),
        ],
        AuthTextField(
          key: const Key('login_phone_field'),
          hintText: l10n.signUpPhoneHint,
          controller: phoneController,
          errorText: phoneError,
          leadingWidget: WhatsAppGlyphIcon(
            size: 20,
            color: phoneError != null
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
          enabled: !isSubmitting,
          onChanged: onPhoneChanged,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AuthDesignTokens.spaceLg),
        AuthPrimaryButton(
          key: const Key('login_submit_button'),
          label: l10n.loginSubmitButton,
          isLoading: isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
