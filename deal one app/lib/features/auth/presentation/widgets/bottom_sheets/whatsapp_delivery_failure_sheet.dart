import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:market_space/features/auth/presentation/l10n/auth_l10n_extension.dart';
import 'package:market_space/features/auth/presentation/theme/auth_design_tokens.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_brand_icons.dart';
import 'package:market_space/features/auth/presentation/widgets/common/auth_secondary_button.dart';

/// Modal bottom sheet matching `Verification via OTP code _Unable to send to WhatsApp State_.png`,
/// surfaced with a blurred backdrop when OTP delivery fails or when troubleshooting delivery.
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            color: AuthDesignTokens.surfaceOf(sheetContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: WhatsAppDeliveryFailureSheet(
            displayPhone: displayPhone,
            subtitle: subtitle,
            onEditPhone: onEditPhone,
            onSendViaSms: onSendViaSms,
            onTryEmail: onTryEmail,
            onContactSupport: onContactSupport,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
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
              color: AuthDesignTokens.borderOf(context),
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
                  child: Icon(
                    Icons.speaker_notes_off_outlined,
                    size: 30,
                    color: AuthDesignTokens.errorForegroundOf(context),
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
            l10n.whatsappFailureTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: AuthDesignTokens.spaceSm),
          Text(
            subtitle?.trim().isNotEmpty == true
                ? subtitle!
                : l10n.whatsappFailureDefaultSubtitle,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GmailMarkIcon(size: 20),
                  const SizedBox(width: AuthDesignTokens.spaceMd - 2),
                  Flexible(
                    child: Text(
                      l10n.whatsappFailureSendEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
            label: l10n.whatsappFailureResendSms,
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
              l10n.whatsappFailureEditPhone,
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
              l10n.whatsappFailureNeedHelp,
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
