import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import '../common/auth_primary_button.dart';
import '../common/auth_secondary_button.dart';

/// Modal bottom sheet displayed when the user reports an OTP delivery issue
/// on WhatsApp (Design Screen 8), providing real fallback actions.
class WhatsAppDeliveryFailureSheet extends StatelessWidget {
  final String displayPhone;
  final VoidCallback onEditPhone;
  final VoidCallback onSendViaSms;
  final VoidCallback onTryEmail;
  final VoidCallback onContactSupport;

  const WhatsAppDeliveryFailureSheet({
    super.key,
    required this.displayPhone,
    required this.onEditPhone,
    required this.onSendViaSms,
    required this.onTryEmail,
    required this.onContactSupport,
  });

  static Future<void> show(
    BuildContext context, {
    required String displayPhone,
    required VoidCallback onEditPhone,
    required VoidCallback onSendViaSms,
    required VoidCallback onTryEmail,
    required VoidCallback onContactSupport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuthDesignTokens.backgroundOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WhatsAppDeliveryFailureSheet(
        displayPhone: displayPhone,
        onEditPhone: onEditPhone,
        onSendViaSms: onSendViaSms,
        onTryEmail: onTryEmail,
        onContactSupport: onContactSupport,
      ),
    );
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
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AuthDesignTokens.borderOf(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AuthDesignTokens.errorTintOf(context),
              shape: BoxShape.circle,
              border: Border.all(color: AuthDesignTokens.errorBorder),
            ),
            child: const Icon(
              Icons.sms_failed_outlined,
              size: 30,
              color: AuthDesignTokens.errorRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تعذر الإرسال عبر واتساب',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم نتمكن من إيصال رمز التحقق عبر واتساب إلى الرقم:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.bodyOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AuthDesignTokens.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AuthDesignTokens.borderOf(context)),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                displayPhone,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AuthDesignTokens.headingOf(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            key: const Key('sheet_send_sms_button'),
            label: 'إعادة الإرسال عبر رسالة SMS',
            leadingIcon: Icons.sms_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onSendViaSms();
            },
          ),
          const SizedBox(height: 12),
          AuthSecondaryButton(
            key: const Key('sheet_edit_phone_button'),
            label: 'تعديل رقم الهاتف',
            leadingIcon: Icons.edit_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onEditPhone();
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: const Key('sheet_try_email_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onTryEmail();
                },
                child: const Text(
                  'المحاولة بالبريد الإلكتروني',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AuthDesignTokens.actionBlue,
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: AuthDesignTokens.mutedOf(context)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onContactSupport();
                },
                child: Text(
                  'الدعم الفني',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
