import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/application/notifiers/seller_verification_notifiers.dart';
import 'package:market_space/features/seller_verification/domain/entities/seller_verification_entities.dart';
import 'package:market_space/features/seller_verification/presentation/components/verification_shared_components.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';
import 'package:market_space/features/seller_verification/presentation/widgets/requirements/document_requirements_widgets.dart';
import 'package:market_space/features/seller_verification/services/document_picker/document_picker_service.dart';

class DocumentFormatInfo extends StatelessWidget {
  final SellerVerificationRequirementEntity requirement;

  const DocumentFormatInfo({super.key, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final formats = requirement.acceptedMimeTypes
        .map((m) => m.split('/').last.toUpperCase())
        .join(' • ');
    return Text(
      '$formats (${s.maxSizePrefix} ${requirement.maxFileSizeMb.toStringAsFixed(0)} MB)',
      style: TextStyle(
        fontSize: 11.5,
        color: AppColors.textMutedOf(context),
      ),
    );
  }
}

class DocumentImagePreview extends StatelessWidget {
  final Uint8List bytes;

  const DocumentImagePreview({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.sm,
      child: Image.memory(
        bytes,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: DealOneTokens.softTileBgOf(context),
          child: const Icon(Icons.image_outlined),
        ),
      ),
    );
  }
}

class DocumentPdfPreview extends StatelessWidget {
  const DocumentPdfPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.errorTintOf(context),
        borderRadius: AppRadii.sm,
      ),
      child: Icon(
        Icons.picture_as_pdf_rounded,
        color: AppColors.errorOf(context),
        size: 28,
      ),
    );
  }
}

class DocumentPreviewCard extends StatelessWidget {
  final String fileName;
  final int fileSizeBytes;
  final bool isPdf;
  final Uint8List? imageBytes;

  const DocumentPreviewCard({
    super.key,
    required this.fileName,
    required this.fileSizeBytes,
    required this.isPdf,
    this.imageBytes,
  });

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: DealOneTokens.softTileBgOf(context),
        borderRadius: AppRadii.md,
      ),
      child: Row(
        children: [
          if (isPdf)
            const DocumentPdfPreview()
          else if (imageBytes != null)
            DocumentImagePreview(bytes: imageBytes!)
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DealOneTokens.cardSurfaceOf(context),
                borderRadius: AppRadii.sm,
              ),
              child: const Icon(Icons.insert_drive_file_outlined),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(fileSizeBytes),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: DealOneTokens.textSecondaryOf(context),
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

class DocumentUploadProgressIndicator extends StatelessWidget {
  final double progress;

  const DocumentUploadProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadii.full,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: DealOneTokens.softTileBgOf(context),
            valueColor: const AlwaysStoppedAnimation<Color>(DealOneTokens.navy),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}%',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: DealOneTokens.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }
}

class DocumentUploadSuccess extends StatelessWidget {
  const DocumentUploadSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final green = AppColors.successOf(context);
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: green, size: 16),
        const SizedBox(width: 5),
        Text(
          s.uploadedSuccessLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: green,
          ),
        ),
      ],
    );
  }
}

class DocumentUploadError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DocumentUploadError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final red = AppColors.errorOf(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorTintOf(context),
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: red, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: red),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(s.retryLabel),
            ),
        ],
      ),
    );
  }
}

class DocumentCameraButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentCameraButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.camera_alt_outlined, size: 16),
      label: Text(s.cameraBtn),
    );
  }
}

class DocumentGalleryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentGalleryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.photo_library_outlined, size: 16),
      label: Text(s.galleryBtn),
    );
  }
}

class DocumentFilePickerButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentFilePickerButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.upload_file_outlined, size: 16),
      label: Text(s.filePickerBtn),
    );
  }
}

class DocumentUploadButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentUploadButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: DealOneTokens.navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      icon: const Icon(Icons.cloud_upload_outlined, size: 17),
      label: Text(s.uploadDocumentBtn),
    );
  }
}

class DocumentReplaceButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentReplaceButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
      label: Text(s.replaceDocumentBtn),
    );
  }
}

class DocumentRemoveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const DocumentRemoveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.errorOf(context)),
      icon: const Icon(Icons.delete_outline_rounded, size: 16),
      label: Text(s.removeDocumentBtn),
    );
  }
}

/// Complete independent reusable DocumentUploadCard widget for any requirement.
class DocumentUploadCard extends StatelessWidget {
  final SellerVerificationRequirementEntity requirement;
  final DocumentUploadItemState itemState;
  final void Function(DocumentPickSource source) onPickSource;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;
  final bool allowRemove;

  const DocumentUploadCard({
    super.key,
    required this.requirement,
    required this.itemState,
    required this.onPickSource,
    this.onRetry,
    this.onRemove,
    this.allowRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final isUploading = itemState.status == DocumentUploadSlotStatus.uploading;
    final isUploaded = itemState.status == DocumentUploadSlotStatus.uploaded &&
        itemState.confirmedDocument != null;
    final hasError = itemState.status == DocumentUploadSlotStatus.error &&
        itemState.errorMessage != null;

    final fileName = itemState.confirmedDocument?.originalFileName ??
        itemState.localPreviewFile?.fileName;
    final fileSize = itemState.confirmedDocument?.fileSizeBytes ??
        itemState.localPreviewFile?.sizeBytes ??
        0;
    final isPdf = itemState.confirmedDocument?.isPdf ??
        itemState.localPreviewFile?.isPdf ??
        false;

    return VerificationSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isUploaded
          ? AppColors.successOf(context).withValues(alpha: 0.45)
          : hasError
              ? AppColors.errorOf(context).withValues(alpha: 0.45)
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requirement.localizedName(isArabic: s.isArabic),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              requirement.isRequired
                  ? const RequiredDocumentBadge()
                  : const OptionalDocumentBadge(),
            ],
          ),
          const SizedBox(height: 4),
          DocumentFormatInfo(requirement: requirement),
          const SizedBox(height: AppSpacing.sm),
          if (fileName != null && fileName.isNotEmpty) ...[
            DocumentPreviewCard(
              fileName: fileName,
              fileSizeBytes: fileSize,
              isPdf: isPdf,
              imageBytes: itemState.localPreviewFile?.isImage == true
                  ? itemState.localPreviewFile!.bytes
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (isUploading) ...[
            DocumentUploadProgressIndicator(progress: itemState.progress),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (isUploaded) ...[
            const DocumentUploadSuccess(),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (hasError) ...[
            DocumentUploadError(
              message: itemState.errorMessage!,
              onRetry: itemState.localPreviewFile != null ? onRetry : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (!isUploading)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (!isUploaded) ...[
                  DocumentCameraButton(
                    onPressed: () => onPickSource(DocumentPickSource.camera),
                  ),
                  DocumentGalleryButton(
                    onPressed: () => onPickSource(DocumentPickSource.gallery),
                  ),
                  DocumentFilePickerButton(
                    onPressed: () => onPickSource(DocumentPickSource.file),
                  ),
                ] else ...[
                  DocumentReplaceButton(
                    onPressed: () => onPickSource(DocumentPickSource.file),
                  ),
                  if (allowRemove && onRemove != null)
                    DocumentRemoveButton(onPressed: onRemove!),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
