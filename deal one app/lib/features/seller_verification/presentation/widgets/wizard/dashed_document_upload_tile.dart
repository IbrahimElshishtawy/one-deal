import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_wizard_notifier.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent dashed-border document upload tile (`وجه البطاقة` / `ظهر البطاقة`
/// or `السجل التجاري` / `البطاقة الضريبية`) supporting idle, local preview,
/// live upload progress, uploaded check badge, and validation error state.
class DashedDocumentUploadTile extends StatelessWidget {
  final Key? tileKey;
  final String title;
  final String actionHint;
  final IconData icon;
  final WizardDocumentSlot slot;
  final String? validationError;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const DashedDocumentUploadTile({
    super.key,
    this.tileKey,
    required this.title,
    required this.actionHint,
    required this.icon,
    required this.slot,
    this.validationError,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final effectiveError = slot.errorMessage ?? validationError;
    final hasError = effectiveError != null && effectiveError.isNotEmpty;
    final hasFile = slot.hasFile && !hasError;

    final borderColor = hasError
        ? WizardTheme.danger(context)
        : hasFile
            ? WizardTheme.success(context)
            : WizardTheme.dashedBorder(context);

    final bgColor = hasError
        ? WizardTheme.dangerSoft(context)
        : hasFile
            ? WizardTheme.successSoft(context)
            : WizardTheme.cardBg(context);

    return CustomPaint(
      painter: DashedRRectPainter(
        color: borderColor,
        radius: 16,
      ),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: tileKey,
          onTap: slot.isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: slot.isUploading
                ? _buildUploadingState(context, isArabic)
                : slot.localFile != null && !hasError
                    ? _buildLocalPreviewState(context, isArabic)
                    : slot.confirmedDocument != null &&
                            slot.confirmedDocument!.status.isAcceptedOrUploaded &&
                            !hasError
                        ? _buildConfirmedState(context, isArabic)
                        : _buildIdleOrErrorState(
                            context,
                            hasError: hasError,
                            errorText: effectiveError,
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleOrErrorState(
    BuildContext context, {
    required bool hasError,
    required String? errorText,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: hasError
                ? WizardTheme.danger(context).withValues(alpha: 0.12)
                : WizardTheme.softBlueCircleBg(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            hasError ? Icons.error_outline_rounded : icon,
            size: 22,
            color: hasError
                ? WizardTheme.danger(context)
                : WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasError ? errorText! : actionHint,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: hasError
                ? WizardTheme.danger(context)
                : WizardTheme.secondaryInk(context),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingState(BuildContext context, bool isArabic) {
    final pct = (slot.uploadProgress * 100).round().clamp(0, 100);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: slot.uploadProgress > 0 ? slot.uploadProgress : null,
            strokeWidth: 3,
            color: WizardTheme.primaryNavy(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          isArabic ? 'جاري الرفع $pct%' : 'Uploading $pct%',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: WizardTheme.primaryNavy(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalPreviewState(BuildContext context, bool isArabic) {
    final file = slot.localFile!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 48,
                child: file.isImage
                    ? Image.memory(file.bytes, fit: BoxFit.cover)
                    : Container(
                        color: WizardTheme.softBlueCircleBg(context),
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          color: WizardTheme.primaryNavy(context),
                        ),
                      ),
              ),
            ),
            PositionedDirectional(
              top: -6,
              end: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: WizardTheme.success(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WizardTheme.cardBg(context),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                isArabic ? 'جاهز للإرسال' : 'Ready',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: WizardTheme.success(context),
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: WizardTheme.danger(context),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmedState(BuildContext context, bool isArabic) {
    final doc = slot.confirmedDocument!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: WizardTheme.success(context).withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_rounded,
            size: 22,
            color: WizardTheme.success(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: WizardTheme.primaryInk(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          doc.originalFileName.isNotEmpty
              ? doc.originalFileName
              : (isArabic ? 'تم الرفع بنجاح' : 'Uploaded'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: WizardTheme.success(context),
          ),
        ),
      ],
    );
  }
}
