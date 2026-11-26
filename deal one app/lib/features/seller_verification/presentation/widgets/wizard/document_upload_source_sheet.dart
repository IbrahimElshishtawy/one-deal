import 'package:flutter/material.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/wizard/wizard_theme.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';

/// Independent modal bottom sheet allowing users to pick an image or PDF
/// from Camera, Gallery, or Files.
class DocumentUploadSourceSheet extends StatelessWidget {
  final bool includePdfOption;

  const DocumentUploadSourceSheet({
    super.key,
    this.includePdfOption = true,
  });

  static Future<DocumentPickSource?> show(
    BuildContext context, {
    bool includePdfOption = true,
  }) {
    return showModalBottomSheet<DocumentPickSource>(
      context: context,
      backgroundColor: WizardTheme.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) =>
          DocumentUploadSourceSheet(includePdfOption: includePdfOption),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: WizardTheme.border(context),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'اختر مصدر الملف' : 'Select Upload Source',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WizardTheme.primaryInk(context),
              ),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              key: const Key('picker_source_camera'),
              icon: Icons.photo_camera_outlined,
              title: isArabic ? 'التقاط صورة بالكاميرا' : 'Take a Photo',
              subtitle: isArabic
                  ? 'صوّر المستند مباشرة بإضاءة واضحة'
                  : 'Capture document directly with camera',
              onTap: () => Navigator.of(context).pop(DocumentPickSource.camera),
            ),
            const SizedBox(height: 8),
            _SourceTile(
              key: const Key('picker_source_gallery'),
              icon: Icons.photo_library_outlined,
              title: isArabic ? 'اختيار من معرض الصور' : 'Choose from Gallery',
              subtitle: isArabic ? 'JPG, PNG, WEBP' : 'JPG, PNG, WEBP',
              onTap: () =>
                  Navigator.of(context).pop(DocumentPickSource.gallery),
            ),
            if (includePdfOption) ...[
              const SizedBox(height: 8),
              _SourceTile(
                key: const Key('picker_source_file'),
                icon: Icons.picture_as_pdf_outlined,
                title: isArabic ? 'اختيار ملف (PDF / صورة)' : 'Pick File (PDF / Image)',
                subtitle: isArabic
                    ? 'ملفات رسمية بحد أقصى 10 ميجابايت'
                    : 'Official documents up to 10 MB',
                onTap: () => Navigator.of(context).pop(DocumentPickSource.file),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WizardTheme.elevatedCardBg(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WizardTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WizardTheme.softBlueCircleBg(context),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: WizardTheme.primaryInk(context),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: WizardTheme.primaryInk(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: WizardTheme.secondaryInk(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: WizardTheme.secondaryInk(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
