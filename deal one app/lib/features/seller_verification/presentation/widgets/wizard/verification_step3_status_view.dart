import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/domain/algorithms/seller_verification_algorithms.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/domain/enums/seller_verification_enums.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_primary_cta_button.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/verification_trust_banner_card.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent Step 3 of 3 view displaying the official verification status,
/// reference ID, submitted seller metadata, correction/rejection alert if any,
/// and tracking/navigation actions.
class VerificationStep3StatusView extends StatelessWidget {
  final VerificationStatusSnapshot? snapshot;
  final SellerApplicationEntity? application;
  final String officeName;
  final String? activityCode;
  final SellerType identityMode;
  final VoidCallback onTrackTap;
  final VoidCallback onEditResubmitTap;
  final VoidCallback onReturnHomeTap;
  final VoidCallback? onDevApproveTap;
  final bool isDevApproving;

  const VerificationStep3StatusView({
    super.key,
    required this.snapshot,
    required this.application,
    required this.officeName,
    required this.activityCode,
    required this.identityMode,
    required this.onTrackTap,
    required this.onEditResubmitTap,
    required this.onReturnHomeTap,
    this.onDevApproveTap,
    this.isDevApproving = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final status = application?.status ??
        snapshot?.sellerStatus ??
        VerificationStatus.pending;

    final isApproved = status == VerificationStatus.approved;
    final needsAction = status.requiresAction;
    final isSuspended = status == VerificationStatus.suspended;

    final badgeColor = isApproved
        ? WizardTheme.success(context)
        : (needsAction || isSuspended)
            ? WizardTheme.danger(context)
            : WizardTheme.primaryNavy(context);
    final badgeBg = isApproved
        ? WizardTheme.successSoft(context)
        : (needsAction || isSuspended)
            ? WizardTheme.dangerSoft(context)
            : WizardTheme.softBlueBg(context);

    final statusTitle = _statusHeadline(status, isArabic);
    final statusDesc = _statusSubtitle(status, isArabic);
    final reason = application?.correctionReason ??
        application?.rejectionReason ??
        snapshot?.sellerSuspensionReason;

    final activity =
        SellerVerificationAlgorithms.findActivityByCode(activityCode);
    final effectiveName =
        (application?.businessName?.isNotEmpty == true)
            ? application!.businessName!
            : officeName;
    final refCode = application?.id.isNotEmpty == true
        ? '#${application!.id.substring(0, application!.id.length.clamp(0, 8)).toUpperCase()}'
        : '#DEAL-VER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Icon(
              isApproved
                  ? Icons.verified_rounded
                  : needsAction || isSuspended
                      ? Icons.report_problem_outlined
                      : Icons.mark_email_read_outlined,
              size: 40,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          statusTitle,
          key: const Key('wizard_step3_headline'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          statusDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: WizardTheme.secondaryInk(context),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusPillText(status, isArabic),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
        ),
        if (reason != null && reason.trim().isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WizardTheme.dangerSoft(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: WizardTheme.danger(context).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: WizardTheme.danger(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: WizardTheme.primaryInk(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WizardTheme.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WizardTheme.border(context)),
            boxShadow: WizardTheme.inputShadow(context),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: isArabic ? 'رقم المرجع' : 'Reference ID',
                value: refCode,
              ),
              Divider(height: 20, color: WizardTheme.border(context)),
              if (effectiveName.isNotEmpty) ...[
                _SummaryRow(
                  label: isArabic ? 'اسم الحساب / المكتب' : 'Account Name',
                  value: effectiveName,
                ),
                Divider(height: 20, color: WizardTheme.border(context)),
              ],
              _SummaryRow(
                label: isArabic ? 'تصنيف البائع' : 'Seller Category',
                value: identityMode == SellerType.business
                    ? (isArabic ? 'شركة / مكتب عقاري' : 'Company / Office')
                    : (isArabic ? 'فرد / مسوق مستقل' : 'Individual Seller'),
              ),
              if (activity != null) ...[
                Divider(height: 20, color: WizardTheme.border(context)),
                _SummaryRow(
                  label: isArabic ? 'نوع النشاط' : 'Activity',
                  value: activity.localizedTitle(isArabic),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        VerificationTrustBannerCard(
          title: isArabic
              ? 'مراجعة أمان وموثوقية Deal One'
              : 'Deal One Trust & Safety',
          body: isArabic
              ? 'يتم حفظ بياناتك ومستنداتك الشخصية بشكل مشفر ومؤمن بالكامل ولا تظهر للعملاء.'
              : 'Your identity documents are stored in encrypted private storage and are never shared publicly.',
        ),
        const SizedBox(height: 22),
        if (kDebugMode && status.isInReview && onDevApproveTap != null) ...[
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              key: const Key('wizard_dev_approve_btn'),
              onPressed: isDevApproving ? null : onDevApproveTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: WizardTheme.success(context)),
                foregroundColor: WizardTheme.success(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isDevApproving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: WizardTheme.success(context),
                      ),
                    )
                  : const Icon(Icons.verified_outlined, size: 20),
              label: Text(
                isArabic
                    ? 'تفعيل حساب البائع فوراً للتجربة (Dev Mode)'
                    : 'Activate Seller Account Now (Dev Mode)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (needsAction) ...[
          VerificationPrimaryCtaButton(
            key: const Key('wizard_edit_resubmit_btn'),
            label: isArabic ? 'تعديل البيانات وإعادة الإرسال' : 'Edit & Resubmit',
            onPressed: onEditResubmitTap,
          ),
          const SizedBox(height: 10),
        ] else ...[
          VerificationPrimaryCtaButton(
            key: const Key('wizard_track_status_btn'),
            label: isArabic ? 'متابعة تفاصيل الطلب' : 'Track Application Status',
            onPressed: onTrackTap,
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 50,
          child: OutlinedButton(
            key: const Key('wizard_return_home_btn'),
            onPressed: onReturnHomeTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: WizardTheme.border(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isArabic ? 'العودة للرئيسية' : 'Back to Home',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: WizardTheme.primaryInk(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusHeadline(VerificationStatus status, bool isArabic) {
    switch (status) {
      case VerificationStatus.approved:
        return isArabic ? 'تم توثيق حسابك بنجاح' : 'Your Account is Verified';
      case VerificationStatus.needsChanges:
        return isArabic
            ? 'مطلوب استكمال أو تعديل البيانات'
            : 'Corrections Requested';
      case VerificationStatus.rejected:
        return isArabic
            ? 'تم رفض طلب التوثيق'
            : 'Verification Application Rejected';
      case VerificationStatus.suspended:
        return isArabic ? 'حساب البائع معلق مؤقتاً' : 'Seller Access Suspended';
      case VerificationStatus.expired:
        return isArabic ? 'انتهت صلاحية التوثيق' : 'Verification Expired';
      case VerificationStatus.withdrawn:
        return isArabic ? 'تم سحب طلب التوثيق' : 'Application Withdrawn';
      default:
        return isArabic
            ? 'تم إرسال طلبك للمراجعة بنجاح'
            : 'Application Submitted for Review';
    }
  }

  String _statusSubtitle(VerificationStatus status, bool isArabic) {
    switch (status) {
      case VerificationStatus.approved:
        return isArabic
            ? 'يمكنك الآن نشر إعلاناتك واستقبال طلبات المعاينة بشارة التوثيق الرسمية.'
            : 'You can now publish listings and receive inquiries with your official badge.';
      case VerificationStatus.needsChanges:
      case VerificationStatus.rejected:
      case VerificationStatus.expired:
        return isArabic
            ? 'راجع الملاحظات التالية وقم بتحديث بياناتك أو مستنداتك لإعادة الإرسال.'
            : 'Review the notes below and update your details or documents to resubmit.';
      case VerificationStatus.suspended:
        return isArabic
            ? 'يرجى التواصل مع فريق دعم الصفقة الأولى لمراجعة حالة حسابك.'
            : 'Please contact Deal One support regarding your account status.';
      default:
        return isArabic
            ? 'يقوم فريق التوثيق بمراجعة مستنداتك حالياً وسيتم إشعارك فور التفعيل.'
            : 'Our verification team is reviewing your documents and will notify you shortly.';
    }
  }

  String _statusPillText(VerificationStatus status, bool isArabic) {
    switch (status) {
      case VerificationStatus.approved:
        return isArabic ? 'موثّق ونشط' : 'Verified & Active';
      case VerificationStatus.underReview:
        return isArabic ? 'تحت المراجعة الآن' : 'Under Review';
      case VerificationStatus.needsChanges:
        return isArabic ? 'مطلوب تعديل' : 'Needs Correction';
      case VerificationStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case VerificationStatus.suspended:
        return isArabic ? 'معلق' : 'Suspended';
      case VerificationStatus.expired:
        return isArabic ? 'منتهي الصلاحية' : 'Expired';
      case VerificationStatus.withdrawn:
        return isArabic ? 'تم السحب' : 'Withdrawn';
      default:
        return isArabic ? 'قيد المراجعة' : 'Pending Review';
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: WizardTheme.secondaryInk(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: WizardTheme.primaryInk(context),
            ),
          ),
        ),
      ],
    );
  }
}
