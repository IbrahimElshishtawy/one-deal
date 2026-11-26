import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/seller_verification/presentation/l10n/seller_verification_strings.dart';

/// Consistent verification flow app bar supporting RTL/LTR and dark/light themes.
class VerificationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const VerificationAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DealOneTokens.pageBgOf(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: DealOneTokens.textPrimaryOf(context),
              ),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: DealOneTokens.textPrimaryOf(context),
        ),
      ),
      actions: actions,
    );
  }
}

/// Multi-step verification progress bar (`FormProgressIndicator` / `VerificationStepProgress`).
class VerificationStepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const VerificationStepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final s = SellerVerificationStrings.of(context);
    final fraction = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${s.stepProgressPrefix} $currentStep ${s.ofLabel} $totalSteps',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: DealOneTokens.textSecondaryOf(context),
              ),
            ),
            Text(
              '${(fraction * 100).round()}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadii.full,
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: DealOneTokens.softTileBgOf(context),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.isDark(context)
                  ? DealOneTokens.amberWarm
                  : DealOneTokens.navy,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable elevated card surface adhering to Deal One design tokens.
class VerificationSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  const VerificationSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? DealOneTokens.cardPadding,
      decoration: DealOneTokens.cardDecoration(
        context,
        color: color,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

/// Primary CTA button used across onboarding, forms, upload, review, and upgrade steps.
class ContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  const ContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (AppColors.isDark(context) ? DealOneTokens.amberWarm : DealOneTokens.navy);
    final fg = AppColors.isDark(context) && backgroundColor == null
        ? AppColors.darkOnPrimary
        : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: DealOneTokens.buttonMinHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.disabledOf(context),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum VerificationNoticeTone { info, success, warning, error }

/// Semantic banner for notices, warnings, and errors.
class VerificationNoticeBanner extends StatelessWidget {
  final String title;
  final String message;
  final VerificationNoticeTone tone;
  final IconData? icon;

  const VerificationNoticeBanner({
    super.key,
    required this.title,
    required this.message,
    this.tone = VerificationNoticeTone.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final (Color accent, Color bg, IconData defaultIcon) = switch (tone) {
      VerificationNoticeTone.success => (
          AppColors.successOf(context),
          isDark ? AppColors.darkSuccessTint : AppColors.successTint,
          Icons.check_circle_outline_rounded,
        ),
      VerificationNoticeTone.warning => (
          AppColors.warningOf(context),
          isDark ? AppColors.darkWarningTint : AppColors.warningTint,
          Icons.warning_amber_rounded,
        ),
      VerificationNoticeTone.error => (
          AppColors.errorOf(context),
          isDark ? AppColors.darkErrorTint : AppColors.errorTint,
          Icons.error_outline_rounded,
        ),
      VerificationNoticeTone.info => (
          AppColors.infoOf(context),
          isDark ? AppColors.darkInfoTint : AppColors.infoTint,
          Icons.info_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.md,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: accent, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: DealOneTokens.textPrimaryOf(context),
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

/// Inline validation error banner for form & server validation messages.
class FormValidationMessage extends StatelessWidget {
  final String? message;

  const FormValidationMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final errColor = AppColors.errorOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorTintOf(context),
        borderRadius: AppRadii.sm,
        border: Border.all(color: errColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: errColor, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: errColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight loading skeleton matching Deal One cards.
class VerificationLoadingSkeleton extends StatelessWidget {
  final int cardCount;

  const VerificationLoadingSkeleton({super.key, this.cardCount = 3});

  @override
  Widget build(BuildContext context) {
    final fill = DealOneTokens.softTileBgOf(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cardCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => Container(
        height: 92,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: DealOneTokens.cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.xs,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 11,
              width: double.infinity,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadii.xs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
