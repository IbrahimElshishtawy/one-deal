import 'package:flutter/material.dart';

import '../../../domain/validators/auth_validators.dart';
import '../../theme/auth_design_tokens.dart';
import '../common/auth_error_banner.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_text_field.dart';

/// Email fallback modal with full validation and transparent backend status
/// communication (never fabricates unsupported email OTP delivery).
class EmailFallbackSheet extends StatefulWidget {
  const EmailFallbackSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EmailFallbackSheet(),
    );
  }

  @override
  State<EmailFallbackSheet> createState() => _EmailFallbackSheetState();
}

class _EmailFallbackSheetState extends State<EmailFallbackSheet> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  String? _unsupportedNotice;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final error = EmailValidator.validate(_emailController.text);
    if (error != null) {
      setState(() {
        _emailError = error;
        _unsupportedNotice = null;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _unsupportedNotice =
          'إرسال رمز التحقق عبر البريد الإلكتروني غير متاح حالياً من الخادم. يرجى إتمام التحقق عبر رسالة SMS على رقم الموبايل المصري (+20).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AuthDesignTokens.borderOf(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'التحقق بالبريد الإلكتروني',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بريدك الإلكتروني للتحقق من إمكانية إرسال رمز بديل.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.bodyOf(context),
            ),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            key: const Key('email_fallback_field'),
            label: 'البريد الإلكتروني',
            hintText: 'name@example.com',
            controller: _emailController,
            errorText: _emailError,
            leadingIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            onChanged: (_) {
              if (_emailError != null || _unsupportedNotice != null) {
                setState(() {
                  _emailError = null;
                  _unsupportedNotice = null;
                });
              }
            },
            onSubmitted: (_) => _handleSubmit(),
          ),
          if (_unsupportedNotice != null) ...[
            const SizedBox(height: 14),
            AuthErrorBanner(
              key: const Key('email_fallback_notice'),
              message: _unsupportedNotice!,
              icon: Icons.info_outline_rounded,
            ),
          ],
          const SizedBox(height: 18),
          AuthPrimaryButton(
            key: const Key('email_fallback_submit'),
            label: 'التحقق من البريد الإلكتروني',
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
