import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../application/state/auth_states.dart';
import '../../../domain/entities/auth_session.dart';
import '../../providers/auth_providers.dart';
import '../../theme/auth_design_tokens.dart';
import '../../widgets/bottom_sheets/email_fallback_sheet.dart';
import '../../widgets/bottom_sheets/support_contact_sheet.dart';
import '../../widgets/bottom_sheets/whatsapp_delivery_failure_sheet.dart';
import '../../widgets/common/auth_error_banner.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/otp/otp_countdown_timer.dart';
import '../../widgets/otp/otp_delivery_help_row.dart';
import '../../widgets/otp/otp_pin_boxes.dart';

/// Deal One OTP Verification page covering Default, Invalid Code, Expired Code,
/// and WhatsApp Delivery Failure Sheet (Design Screens 5–8).
class OtpVerificationPage extends ConsumerWidget {
  final PendingAuthContext? authContext;

  const OtpVerificationPage({super.key, required this.authContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = authContext;
    if (pending == null) {
      return AuthScaffoldShell(
        centerVertically: true,
        child: Column(
          children: [
            const Icon(
              Icons.sms_outlined,
              size: 56,
              color: AuthDesignTokens.actionBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد جلسة تحقق نشطة',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AuthDesignTokens.headingOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى إدخال رقم هاتفك أولاً لاستلام رمز التحقق.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AuthDesignTokens.bodyOf(context),
              ),
            ),
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'العودة لتسجيل الدخول',
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

    Future<void> verifyAndProceed() async {
      final session = await controller.verifyCode();
      if (!context.mounted || session == null) return;
      context.go(RouteNames.verificationSuccess, extra: session);
    }

    Future<void> handleResend() async {
      final resent = await controller.resendCode();
      if (!context.mounted) return;
      if (resent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رمز تحقق جديد بنجاح')),
        );
      }
    }

    void openDeliveryFailureSheet() {
      WhatsAppDeliveryFailureSheet.show(
        context,
        displayPhone: state.displayPhone,
        onEditPhone: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(
              pending.flowMode == AuthFlowMode.signUp
                  ? RouteNames.signUp
                  : RouteNames.login,
            );
          }
        },
        onSendViaSms: () {
          if (state.canResend) {
            handleResend();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يرجى انتظار ${state.formattedCooldown} قبل إعادة الإرسال عبر SMS',
                ),
              ),
            );
          }
        },
        onTryEmail: () => EmailFallbackSheet.show(context),
        onContactSupport: () => SupportContactSheet.show(context),
      );
    }

    return AuthScaffoldShell(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const Key('otp_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                pending.flowMode == AuthFlowMode.signUp
                    ? RouteNames.signUp
                    : RouteNames.login,
              );
            }
          },
        ),
        title: Text(
          'التحقق من رقم الهاتف',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AuthDesignTokens.headingOf(context),
          ),
        ),
        centerTitle: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: state.hasFieldError
                    ? AuthDesignTokens.errorTintOf(context)
                    : AuthDesignTokens.actionBlueTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isExpired
                    ? Icons.timer_off_outlined
                    : (state.hasFieldError
                          ? Icons.gpp_bad_outlined
                          : Icons.mark_chat_read_outlined),
                size: 34,
                color: state.hasFieldError
                    ? AuthDesignTokens.errorRed
                    : AuthDesignTokens.actionBlue,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'أدخل رمز التحقق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AuthDesignTokens.headingOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم إرسال رمز مكون من 6 أرقام إلى الرقم التالي:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AuthDesignTokens.bodyOf(context),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AuthDesignTokens.surfaceOf(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AuthDesignTokens.borderOf(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      state.displayPhone,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.headingOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    key: const Key('otp_edit_phone_chip'),
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.login);
                      }
                    },
                    child: const Text(
                      'تعديل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.actionBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OtpPinBoxes(
            code: state.code,
            hasError: state.hasFieldError,
            enabled: !state.isBusy && !state.isExpired && !state.isLocked,
            onChanged: controller.updateCode,
            onCompleted: verifyAndProceed,
          ),
          if (state.hasBannerError) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(
              key: const Key('otp_error_banner'),
              message: state.errorMessage!,
              icon: state.isExpired
                  ? Icons.schedule_rounded
                  : Icons.error_outline_rounded,
              actionLabel:
                  (state.isExpired || state.isLocked) && state.canResend
                  ? 'إرسال رمز جديد الآن'
                  : null,
              onActionPressed:
                  (state.isExpired || state.isLocked) && state.canResend
                  ? handleResend
                  : null,
            ),
          ],
          if (state.status == OtpStatus.invalid &&
              state.failedAttempts > 0 &&
              state.failedAttempts < state.maxAttempts) ...[
            const SizedBox(height: 8),
            Text(
              'المحاولات المتبقية: ${state.maxAttempts - state.failedAttempts}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AuthDesignTokens.mutedOf(context),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OtpCountdownTimer(
            formattedCooldown: state.formattedCooldown,
            formattedExpiry: state.formattedExpiry,
            cooldownRemainingSeconds: state.cooldownRemainingSeconds,
            isExpired: state.isExpired,
            isResending: state.isResending,
            canResend: state.canResend,
            onResendPressed: handleResend,
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            key: const Key('otp_verify_button'),
            label: 'تأكيد الرمز',
            isLoading: state.isVerifying,
            onPressed: state.canSubmit ? verifyAndProceed : null,
          ),
          const SizedBox(height: 16),
          OtpDeliveryHelpRow(
            onDeliveryTroubleTap: openDeliveryFailureSheet,
            onSupportTap: () => SupportContactSheet.show(context),
          ),
        ],
      ),
    );
  }
}
