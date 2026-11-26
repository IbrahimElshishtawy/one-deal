import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';

/// Independent dashed-border Profile / Logo upload card matching Screenshot 2:
/// Header (`صورة البروفايل أو الشعار` + `اختياري`), circular camera/preview circle,
/// helper description, and deep-navy `اختر ملفاً` CTA button.
class ProfileLogoUploadCard extends StatelessWidget {
  final PickedDocumentFile? localFile;
  final SellerDocumentEntity? confirmedDocument;
  final VoidCallback onPickTap;
  final VoidCallback? onRemoveTap;

  const ProfileLogoUploadCard({
    super.key,
    this.localFile,
    this.confirmedDocument,
    required this.onPickTap,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hasFile = localFile != null || confirmedDocument != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isArabic
                    ? 'صورة البروفايل أو الشعار'
                    : 'Profile Photo or Logo',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: WizardTheme.primaryInk(context),
                ),
              ),
            ),
            Text(
              isArabic ? 'اختياري' : 'Optional',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: WizardTheme.secondaryInk(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CustomPaint(
          painter: DashedRRectPainter(
            color: hasFile
                ? WizardTheme.success(context)
                : WizardTheme.dashedBorder(context),
            radius: 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WizardTheme.cardBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                GestureDetector(
                  key: const Key('wizard_logo_circle_picker'),
                  onTap: onPickTap,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: WizardTheme.softBlueCircleBg(context),
                      shape: BoxShape.circle,
                      border: hasFile
                          ? Border.all(
                              color: WizardTheme.success(context),
                              width: 2,
                            )
                          : null,
                    ),
                    child: ClipOval(
                      child: localFile != null
                          ? Image.memory(
                              localFile!.bytes,
                              fit: BoxFit.cover,
                            )
                          : confirmedDocument != null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 28,
                                      color: WizardTheme.success(context),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isArabic ? 'مرفوعة' : 'Uploaded',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: WizardTheme.success(context),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 24,
                                      color: WizardTheme.primaryInk(context),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isArabic ? 'أضف صورة' : 'Add photo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: WizardTheme.secondaryInk(context),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localFile?.fileName ??
                            confirmedDocument?.originalFileName ??
                            (isArabic
                                ? 'أضف صورة شخصية واضحة أو شعار علامتك لتظهر رسمياً في بطاقة التعريف العقارية.'
                                : 'Add a clear personal photo or brand logo to appear on your official seller card.'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: hasFile ? FontWeight.w700 : FontWeight.w400,
                          color: hasFile
                              ? WizardTheme.primaryInk(context)
                              : WizardTheme.secondaryInk(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            key: const Key('wizard_logo_pick_btn'),
                            onPressed: onPickTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  WizardTheme.primaryButtonBg(context),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.upload_file_outlined,
                              size: 16,
                            ),
                            label: Text(
                              hasFile
                                  ? (isArabic ? 'تغيير الصورة' : 'Change')
                                  : (isArabic ? 'اختر ملفاً' : 'Choose File'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (hasFile && onRemoveTap != null)
                            IconButton(
                              onPressed: onRemoveTap,
                              tooltip: isArabic ? 'حذف' : 'Remove',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: WizardTheme.danger(context),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
