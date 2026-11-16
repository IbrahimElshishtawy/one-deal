import 'dart:ui';

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
import '../../widgets/common/auth_legal_footer.dart';
import '../../widgets/common/auth_logo_header.dart';
import '../../widgets/common/auth_primary_button.dart';
import '../../widgets/common/auth_scaffold_shell.dart';
import '../../widgets/otp/otp_pin_boxes.dart';
import '../verification_success/verification_success_page.dart';

/// Deal One OTP Verification page matching:
/// - `ui/otp.png` (default state)
/// - `ui/لو المستخدم دخل الرمز غلط.png` (invalid OTP state)
/// - `ui/لو الكود صلاحيات خلصت .png` (expired OTP state)
/// - `ui/هنا لو المستخدم الرقم مش موجود عليها واتس.png` (delivery failure sheet)
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

  String _formatRemainingAttemptsText(int remaining) {
    if (remaining == 1) {
      return 'متبقي لك محاولة واحدة (1) فقط قبل القفل المؤقت';
    }
    if (remaining == 2) {
      return 'متبقي لك محاولتان (2) فقط قبل القفل المؤقت';
    }
    return 'متبقي لك $remaining محاولات فقط قبل القفل المؤقت';
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.authContext;
    if (pending == null) {
      return AuthScaffoldShell(
        centerVertically: true,
        child: Column(
          children: [
            const Icon(
              Icons.sms_outlined,
              size: 56,
              color: AuthDesignTokens.navyPrimary,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رمز تحقق جديد بنجاح')),
        );
        _otpFocusNode.requestFocus();
        return;
      }
      final updated = ref.read(otpVerificationControllerProvider(pending));
      if (updated.isDeliveryFailed) {
        openDeliveryFailureSheet(customReason: updated.errorMessage);
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
                'يرجى انتظار ${state.formattedCooldown} قبل طلب رمز جديد',
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
          title: 'أدخل رمز التحقق',
          subtitle:
              'أدخل الرمز المكون من 6 أرقام المرسل إلى\n[${state.displayPhone}]',
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
                    'تغيير الرقم',
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
          // Upper section blurs & dims when OTP has expired (`لو الكود صلاحيات خلصت .png`)
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
                  child: _ExpiredOtpAlertCard(key: Key('otp_expired_card')),
                ),
              ],
            )
          else
            upperContent,

          // Invalid / Error / Locked state banner + remaining attempts pill (`لو المستخدم دخل الرمز غلط.png`)
          if (!state.isExpired && state.hasBannerError) ...[
            const SizedBox(height: AuthDesignTokens.spaceBase),
            AuthErrorBanner(
              key: const Key('otp_error_banner'),
              message: state.errorMessage!,
              icon: Icons.error_rounded,
            ),
          ],
          if (!state.isExpired &&
              (state.isInvalid || state.isLocked) &&
              state.failedAttempts > 0 &&
              state.failedAttempts < state.maxAttempts) ...[
            const SizedBox(height: AuthDesignTokens.spaceMd),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AuthDesignTokens.spaceBase,
                  vertical: AuthDesignTokens.spaceSm - 2,
                ),
                decoration: BoxDecoration(
                  color: AuthDesignTokens.softPillOf(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AuthDesignTokens.mutedOf(context),
                    ),
                    const SizedBox(width: AuthDesignTokens.spaceSm - 2),
                    Flexible(
                      child: Text(
                        _formatRemainingAttemptsText(state.remainingAttempts),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AuthDesignTokens.bodyOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AuthDesignTokens.spaceXl),

          // Primary CTA: "تأكيد الرمز" in normal state, "إعادة المحاولة" on error/expired
          if (showRetryButton)
            AuthPrimaryButton(
              key: state.isExpired
                  ? const Key('otp_resend_button')
                  : const Key('otp_retry_button'),
              label: state.isResending
                  ? 'جاري إرسال رمز جديد...'
                  : (state.isExpired && state.cooldownRemainingSeconds > 0
                        ? 'إعادة المحاولة (${state.formattedCooldown})'
                        : 'إعادة المحاولة'),
              leadingIcon: Icons.refresh_rounded,
              isLoading: state.isResending,
              onPressed: state.isBusy ? null : handleRetryAction,
            )
          else
            AuthPrimaryButton(
              key: const Key('otp_verify_button'),
              label: 'تأكيد الرمز',
              isLoading: state.isVerifying,
              onPressed: state.canSubmit ? verifyAndProceed : null,
            ),

          const SizedBox(height: AuthDesignTokens.spaceBase),

          // Resend countdown row (default `otp.png`) or support row (`لو المستخدم دخل الرمز غلط.png` / expired)
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
                  'تواجه مشكلة في تسجيل الدخول؟ تواصل مع الدعم',
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
                        ? 'إرسال رمز جديد خلال ${state.formattedCooldown}'
                        : 'طلب رمز تحقق جديد',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: state.canResend
                          ? AuthDesignTokens.actionBlue
                          : AuthDesignTokens.mutedOf(context),
                    ),
                  ),
                ),
              ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ألم تستلم الرمز؟ ',
                  style: TextStyle(
                    fontSize: 13,
                    color: AuthDesignTokens.mutedOf(context),
                  ),
                ),
                if (state.cooldownRemainingSeconds > 0 && !state.isResending)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${state.formattedCooldown} إرسال مجدداً',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AuthDesignTokens.headingOf(context),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    key: const Key('otp_resend_button'),
                    onTap: state.canResend ? handleResend : null,
                    child: Text(
                      state.isResending ? 'جاري الإرسال...' : 'إرسال مجدداً',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AuthDesignTokens.actionBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'صلاحية الرمز المتبقية: ${state.formattedExpiry}',
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
                child: const Text(
                  'لم يصلك الرمز عبر واتساب؟',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AuthDesignTokens.actionBlue,
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

class _ExpiredOtpAlertCard extends StatelessWidget {
  const _ExpiredOtpAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthDesignTokens.expiredCardOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_off_outlined,
              size: 24,
              color: AuthDesignTokens.errorDeepRed,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انتهت صلاحية رمز التحقق، يرجى طلب رمز جديد',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AuthDesignTokens.errorDeepRed,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'انقضت مهلة الأمان المحددة لحماية حسابك ومعاملاتك العقارية. يمكنك إنشاء رمز جديد فوري ومتابعة توثيق العملية.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AuthDesignTokens.errorDeepRed,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
