import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_wizard_notifier.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Respectable multi-stage animated submission loader overlay showing live
/// pipeline steps (`التحقق` -> `حفظ البيانات` -> `رفع المستندات %` -> `الإرسال للمراجعة`)
/// with Light & Dark adaptive styling and clean error retry recovery.
class VerificationSubmissionLoaderOverlay extends StatelessWidget {
  final WizardSubmissionStage stage;
  final double progress;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  const VerificationSubmissionLoaderOverlay({
    super.key,
    required this.stage,
    required this.progress,
    this.errorMessage,
    required this.onRetry,
    required this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final isFailed = stage == WizardSubmissionStage.failed;
    final pct = (progress * 100).round().clamp(0, 100);

    final steps = [
      (
        WizardSubmissionStage.validating,
        isArabic ? 'التحقق من صحة البيانات' : 'Validating details',
      ),
      (
        WizardSubmissionStage.savingProfile,
        isArabic ? 'حفظ ملف البائع والنشاط' : 'Saving seller profile',
      ),
      (
        WizardSubmissionStage.uploadingDocuments,
        isArabic ? 'رفع وتشفير المستندات ($pct%)' : 'Encrypting & uploading docs ($pct%)',
      ),
      (
        WizardSubmissionStage.submittingApplication,
        isArabic ? 'إرسال الطلب للمراجعة الرسمية' : 'Submitting for verification',
      ),
    ];

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.56),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: WizardTheme.cardBg(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: WizardTheme.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: isFailed
                          ? WizardTheme.dangerSoft(context)
                          : WizardTheme.softBlueCircleBg(context),
                      shape: BoxShape.circle,
                    ),
                    child: isFailed
                        ? Icon(
                            Icons.error_outline_rounded,
                            size: 32,
                            color: WizardTheme.danger(context),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 3.2,
                              color: WizardTheme.primaryNavy(context),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isFailed
                      ? (isArabic ? 'تعذر إرسال الطلب' : 'Submission Failed')
                      : (isArabic
                          ? 'جاري تجهيز وإرسال طلب التوثيق'
                          : 'Submitting Verification Request'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: WizardTheme.primaryInk(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isFailed
                      ? (errorMessage ??
                          (isArabic
                              ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.'
                              : 'An error occurred while processing your request.'))
                      : (isArabic
                          ? 'يرجى الانتظار قليلاً حتى يكتمل رفع المستندات بأمان...'
                          : 'Please wait while we securely upload your documents...'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isFailed
                        ? WizardTheme.danger(context)
                        : WizardTheme.secondaryInk(context),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isFailed) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.05, 1.0),
                      minHeight: 7,
                      backgroundColor: WizardTheme.progressTrack(context),
                      color: WizardTheme.primaryNavy(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...steps.map((item) {
                    final stepStage = item.$1;
                    final label = item.$2;
                    final isDone = stepStage.index < stage.index ||
                        stage == WizardSubmissionStage.completed;
                    final isActive = stepStage == stage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: isDone
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: WizardTheme.success(context),
                                  )
                                : isActive
                                    ? Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color:
                                              WizardTheme.primaryNavy(context),
                                        ),
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked_rounded,
                                        size: 19,
                                        color: WizardTheme.hintInk(context),
                                      ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive || isDone
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDone
                                    ? WizardTheme.success(context)
                                    : isActive
                                        ? WizardTheme.primaryInk(context)
                                        : WizardTheme.secondaryInk(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDismissError,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            side: BorderSide(color: WizardTheme.border(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'مراجعة البيانات' : 'Review Form',
                            style: TextStyle(
                              color: WizardTheme.primaryInk(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                WizardTheme.primaryButtonBg(context),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'إعادة المحاولة' : 'Retry',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
