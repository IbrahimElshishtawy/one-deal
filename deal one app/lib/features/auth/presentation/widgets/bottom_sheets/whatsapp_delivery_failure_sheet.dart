import 'package:flutter/material.dart';

import '../../theme/auth_design_tokens.dart';
import '../common/auth_brand_icons.dart';
import '../common/auth_secondary_button.dart';

/// Modal bottom sheet matching `هنا لو المستخدم الرقم مش موجود عليها واتس.png`,
/// surfaced when OTP delivery via WhatsApp/SMS fails or when troubleshooting delivery.
class WhatsAppDeliveryFailureSheet extends StatelessWidget {
  final String displayPhone;
  final String? subtitle;
  final VoidCallback onEditPhone;
  final VoidCallback onSendViaSms;
  final VoidCallback onTryEmail;
  final VoidCallback onContactSupport;

  const WhatsAppDeliveryFailureSheet({
    super.key,
    required this.displayPhone,
    this.subtitle,
    required this.onEditPhone,
    required this.onSendViaSms,
    required this.onTryEmail,
    required this.onContactSupport,
  });

  static Future<void> show(
    BuildContext context, {
    required String displayPhone,
    String? subtitle,
    required VoidCallback onEditPhone,
    required VoidCallback onSendViaSms,
    required VoidCallback onTryEmail,
    required VoidCallback onContactSupport,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AuthDesignTokens.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WhatsAppDeliveryFailureSheet(
        displayPhone: displayPhone,
        subtitle: subtitle,
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
        AuthDesignTokens.spaceXl,
        AuthDesignTokens.spaceMd,
        AuthDesignTokens.spaceXl,
        AuthDesignTokens.spaceXl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceLg),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AuthDesignTokens.errorTintOf(context),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.speaker_notes_off_outlined,
                    size: 30,
                    color: AuthDesignTokens.errorDeepRed,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AuthDesignTokens.errorDeepRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AuthDesignTokens.surfaceOf(context),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceBase),
          Text(
            'تعذر الإرسال عبر واتساب',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceSm),
          Text(
            subtitle?.trim().isNotEmpty == true ? subtitle! : 'عذراً، هذا الرقم غير مسجل على تطبيق واتساب. يرجى استخدام طريقة أخرى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AuthDesignTokens.mutedOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceBase),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AuthDesignTokens.spaceBase,
              vertical: AuthDesignTokens.spaceSm,
            ),
            decoration: BoxDecoration(
              color: AuthDesignTokens.softPillOf(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smartphone_outlined,
                  size: 16,
                  color: AuthDesignTokens.mutedOf(context),
                ),
                const SizedBox(width: AuthDesignTokens.spaceSm),
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      displayPhone,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.headingOf(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AuthDesignTokens.spaceSm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AuthDesignTokens.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceXl),
          SizedBox(
            width: double.infinity,
            height: AuthDesignTokens.buttonHeight,
            child: FilledButton(
              key: const Key('sheet_try_email_button'),
              onPressed: () {
                Navigator.of(context).pop();
                onTryEmail();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AuthDesignTokens.primaryActionOf(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AuthDesignTokens.buttonRadius,
                  ),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GmailMarkIcon(size: 20),
                  SizedBox(width: AuthDesignTokens.spaceMd - 2),
                  Flexible(
                    child: Text(
                      'إرسال رسالة عبر البريد الإلكتروني',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceMd),
          AuthSecondaryButton(
            key: const Key('sheet_send_sms_button'),
            label: 'إعادة الإرسال عبر رسالة SMS',
            leadingIcon: Icons.sms_outlined,
            onPressed: () {
              Navigator.of(context).pop();
              onSendViaSms();
            },
          ),
          const SizedBox(height: AuthDesignTokens.spaceMd),
          TextButton.icon(
            key: const Key('sheet_edit_phone_button'),
            onPressed: () {
              Navigator.of(context).pop();
              onEditPhone();
            },
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AuthDesignTokens.headingOf(context),
            ),
            label: Text(
              'تعديل الرقم',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AuthDesignTokens.headingOf(context),
              ),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceXs),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onContactSupport();
            },
            icon: Icon(
              Icons.headset_mic_outlined,
              size: 16,
              color: AuthDesignTokens.mutedOf(context),
            ),
            label: Text(
              'تحتاج مساعدة في تسجيل الدخول؟',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AuthDesignTokens.mutedOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
