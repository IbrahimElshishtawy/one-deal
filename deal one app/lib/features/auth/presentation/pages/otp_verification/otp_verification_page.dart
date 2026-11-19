import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../application/state/auth_states.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/validators/auth_validators.dart';
import '../../l10n/auth_l10n_extension.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/bottom_sheets/email_fallback_sheet.dart';
import '../../widgets/bottom_sheets/support_contact_sheet.dart';
import '../../widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart';
import '../../widgets/common/auth_error_banner.dart';
import '../../widgets/common/auth_legal_footer.dart';
import '../../widgets/common/auth_logo_header.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/otp/otp_attempts_pill.dart';
import '../../widgets/otp/otp_expired_alert_card.dart';
import '../../widgets/otp/otp_pin_boxes.dart';
import '../verification_success/verification_success_page.dart';

/// Deal One OTP Verification page reproducing all 4 Figma OTP states:
/// - `Verification via OTP code.png` (normal state)
/// - `Verification via OTP code _Faild State_.png` (invalid OTP state)
/// - `Verification via OTP code _Timeout State_.png` (expired OTP state)
/// - `Verification via OTP code _Unable to send to WhatsApp State_.png` (delivery failure sheet)
class OtpVerificationPage extends ConsumerStatefulWidget {
  final PendingAuthContext? authContext;

  const OtpVerificationPage({super.key, required this.authContext});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpFocusNode.dispose();
    super.dispose();
  }

  String? _resolveLocalizedError(
    BuildContext context,
    OtpVerificationState state,
  ) {
    final l10n = context.authL10n;
    if (state.validationErrorCode != null) {
      return AuthLocalizedMessages.otpError(
        l10n,
        state.validationErrorCode,
        fallback: state.errorMessage,
      );
    }
    if (state.errorKind != null) {
      return AuthLocalizedMessages.authError(
        l10n,
        state.errorKind!,
        fallback: state.errorMessage,
      );
    }
    return state.errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.authL10n;
    final pending = widget.authContext;
    if (pending == null) {
      return AuthScaffoldShell(
        centerVertically: true,
        child: Column(
          children: [
            Icon(
              Icons.sms_outlined,
              size: 56,
              color: AuthDesignTokens.primaryActionOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.otpNoActiveSessionTitle,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AuthDesignTokens.headingOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.otpNoActiveSessionSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AuthDesignTokens.bodyOf(context),
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: l10n.otpBackToLogin,
              onPressed: () => context.go(RouteNames.login),
            ),
          ],
        ),
      );
    }

    final state = ref.watch(otpVerificationControllerProvider(pending));
    final controller = ref.read(
      otpVerificationControllerProvider(pending).notifier,
    );
    final localizedError = _resolveLocalizedError(context, state);

    void navigateBackToPhoneEntry() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          pending.flowMode == AuthFlowMode.signUp
              ? RouteNames.signUp
              : RouteNames.login,
        );
      }
    }

    void openDeliveryFailureSheet({String? customReason}) {
      WhatsAppDeliveryFailureSheet.show(
        context,
        displayPhone: state.displayPhone,
        subtitle: customReason,
        onEditPhone: navigateBackToPhoneEntry,
        onSendViaSms: () {
          if (state.canResend) {
            controller.resendCode();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.otpWaitCooldownSms(state.formattedCooldown)),
              ),
            );
          }
        },
        onTryEmail: () => EmailFallbackSheet.show(context),
        onContactSupport: () => SupportContactSheet.show(context),
      );
    }

    Future<void> verifyAndProceed() async {
      final session = await controller.verifyCode();
      if (!context.mounted || session == null) return;
      context.go(
        RouteNames.verificationSuccess,
        extra: VerificationSuccessArgs(
          session: session,
          redirectTo: pending.redirectTo,
        ),
      );
    }

    Future<void> handleResend() async {
      final resent = await controller.resendCode();
      if (!context.mounted) return;
      if (resent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.otpResentSuccess)));
        _otpFocusNode.requestFocus();
        return;
      }
      final updated = ref.read(otpVerificationControllerProvider(pending));
      if (updated.isDeliveryFailed) {
        openDeliveryFailureSheet(
          customReason: _resolveLocalizedError(context, updated),
        );
      }
    }

    void handleRetryAction() {
      if (state.isExpired || state.isLocked) {
        if (state.canResend) {
          handleResend();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.otpWaitCooldownNewCode(state.formattedCooldown),
              ),
            ),
          );
        }
        return;
      }
      controller.retryAfterError();
      _otpFocusNode.requestFocus();
    }

    final isErrorMode = state.isInvalid || state.isLocked || state.isExpired;
    final showRetryButton =
        state.isInvalid ||
        state.isLocked ||
        state.isExpired ||
        state.status == OtpStatus.networkError ||
        state.status == OtpStatus.serverError;

    final upperContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTopBar(
          key: const Key('otp_back_button'),
          onBack: navigateBackToPhoneEntry,
        ),
        const SizedBox(height: AuthDesignTokens.spaceMd),
        AuthLogoHeader(
          title: l10n.otpTitle,
          subtitle: l10n.otpSubtitle(
            OtpCodeValidator.requiredLength,
            state.displayPhone,
          ),
        ),
        const SizedBox(height: AuthDesignTokens.spaceSm),
        Center(
          child: InkWell(
            key: const Key('otp_edit_phone_chip'),
            borderRadius: BorderRadius.circular(8),
            onTap: navigateBackToPhoneEntry,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AuthDesignTokens.spaceSm,
                vertical: AuthDesignTokens.spaceXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.otpChangePhone,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AuthDesignTokens.headingOf(context),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: AuthDesignTokens.spaceXs + 1),
                  Icon(
                    Icons.edit,
                    size: 15,
                    color: AuthDesignTokens.headingOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AuthDesignTokens.headerToFormGap),
        OtpPinBoxes(
          code: state.code,
          focusNode: _otpFocusNode,
          hasError: state.hasFieldError,
          enabled: !state.isBusy && !state.isExpired && !state.isLocked,
          onChanged: controller.updateCode,
          onCompleted: verifyAndProceed,
        ),
      ],
    );

    return AuthScaffoldShell(
      footer: Padding(
        padding: const EdgeInsets.only(bottom: AuthDesignTokens.spaceSm),
        child: AuthLegalFooter(
          onTermsTap: () => context.push(RouteNames.terms),
          onPrivacyTap: () => context.push(RouteNames.privacy),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isExpired)
            Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: Opacity(opacity: 0.45, child: upperContent),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    top:
                        AuthDesignTokens.topBarHeight +
                        AuthDesignTokens.spaceSm,
                  ),
                  child: OtpExpiredAlertCard(key: Key('otp_expired_card')),
                ),
              ],
            )
          else
            upperContent,

          if (!state.isExpired &&
              localizedError != null &&
              localizedError.isNotEmpty) ...[
            const SizedBox(height: AuthDesignTokens.spaceBase),
            AuthErrorBanner(
              key: const Key('otp_error_banner'),
              message: localizedError,
              icon: Icons.error_rounded,
            ),
          ],
          if (!state.isExpired &&
              (state.isInvalid || state.isLocked) &&
              state.failedAttempts > 0 &&
              state.failedAttempts < state.maxAttempts) ...[
            const SizedBox(height: AuthDesignTokens.spaceMd),
            OtpAttemptsPill(remainingAttempts: state.remainingAttempts),
          ],

          const SizedBox(height: AuthDesignTokens.spaceXl),

          if (showRetryButton)
            AuthPrimaryButton(
              key: state.isExpired
                  ? const Key('otp_resend_button')
                  : const Key('otp_retry_button'),
              label: state.isResending
                  ? l10n.otpResendingLabel
                  : (state.isExpired && state.cooldownRemainingSeconds > 0
                        ? l10n.otpRetryWithCooldown(state.formattedCooldown)
                        : l10n.otpRetryButton),
              leadingIcon: Icons.refresh_rounded,
              isLoading: state.isResending,
              onPressed: state.isBusy ? null : handleRetryAction,
            )
          else
            AuthPrimaryButton(
              key: const Key('otp_verify_button'),
              label: l10n.otpVerifyButton,
              isLoading: state.isVerifying,
              onPressed: state.canSubmit ? verifyAndProceed : null,
            ),

          const SizedBox(height: AuthDesignTokens.spaceBase),

          if (isErrorMode) ...[
            Center(
              child: TextButton.icon(
                key: const Key('otp_support_button'),
                onPressed: () => SupportContactSheet.show(context),
                icon: Icon(
                  Icons.headset_mic_outlined,
                  size: 16,
                  color: AuthDesignTokens.mutedOf(context),
                ),
                label: Text(
                  l10n.otpSupportPrompt,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
              ),
            ),
            if (state.isInvalid)
              Center(
                child: TextButton(
                  key: const Key('otp_resend_button'),
                  onPressed: state.canResend ? handleResend : null,
                  child: Text(
                    state.cooldownRemainingSeconds > 0
                        ? l10n.otpResendInCooldown(state.formattedCooldown)
                        : l10n.otpRequestNewCode,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: state.canResend
                          ? AuthDesignTokens.linkOf(context)
                          : AuthDesignTokens.mutedOf(context),
                    ),
                  ),
                ),
              ),
          ] else ...[
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                Text(
                  l10n.otpDidNotReceive,
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
                if (state.cooldownRemainingSeconds > 0 && !state.isResending)
                  Text(
                    l10n.otpResendCountdown(state.formattedCooldown),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AuthDesignTokens.headingOf(context),
                    ),
                  )
                else
                  GestureDetector(
                    key: const Key('otp_resend_button'),
                    onTap: state.canResend ? handleResend : null,
                    child: Text(
                      state.isResending
                          ? l10n.otpSendingLabel
                          : l10n.otpResendAgain,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AuthDesignTokens.linkOf(context),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.otpExpiryRemaining(state.formattedExpiry),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AuthDesignTokens.mutedOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                key: const Key('otp_delivery_help_button'),
                onPressed: () => openDeliveryFailureSheet(),
                child: Text(
                  l10n.otpWhatsappHelp,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AuthDesignTokens.linkOf(context),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
