import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/errors/error_presenter.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/shared/widgets/app_network_image.dart';

/// Top bar matching the Deal One sub-screen headers (Profile, Edit Account,
/// Conversations, Notifications, Photo Gallery) with RTL-aware back button,
/// bold navy title, and optional trailing actions.
class DealOneSubPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBackButton;

  const DealOneSubPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = context.horizontalScreenPadding;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        hPad,
        AppSpacing.md,
        hPad,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            _HeaderBackButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.isSmallPhone ? 19 : 22,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HeaderBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 24,
            color: DealOneTokens.textPrimaryOf(context),
          ),
        ),
      ),
    );
  }
}

/// Reusable Deal One Avatar with optional verified badge or camera edit badge.
class DealOneAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double size;
  final bool isVerified;
  final Widget? badge;
  final VoidCallback? onTap;

  const DealOneAvatar({
    super.key,
    required this.fallbackText,
    this.imageUrl,
    this.size = 56,
    this.isVerified = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim().characters.first.toUpperCase()
        : 'D';

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DealOneTokens.softTileBgOf(context),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: DealOneTokens.softShadow(context),
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? AppNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fallbackIcon: Icons.person_rounded,
              )
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w800,
                    color: DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ),
      ),
    );

    final effectiveBadge = badge ??
        (isVerified
            ? Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: DealOneTokens.amberWarm,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: size * 0.2,
                  color: Colors.white,
                ),
              )
            : null);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            if (effectiveBadge != null)
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: effectiveBadge,
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable empty state widget matching `Non Notification.png` and usable across
/// Profile, Conversations, Notifications, Map View, Gallery, and Reels.
class DealOneEmptyStateView extends StatelessWidget {
  final IconData icon;
  final IconData? badgeIcon;
  final String? statusPill;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? footerText;

  const DealOneEmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.badgeIcon,
    this.statusPill,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = context.horizontalScreenPadding;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Concentric soft circular emblem
              SizedBox(
                width: 118,
                height: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DealOneTokens.softTileBgOf(context)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DealOneTokens.cardSurfaceOf(context),
                        boxShadow: DealOneTokens.cardShadow(context),
                      ),
                      child: Icon(
                        icon,
                        size: 34,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                    ),
                    if (badgeIcon != null)
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: DealOneTokens.amber,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DealOneTokens.cardSurfaceOf(context),
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            badgeIcon,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (statusPill != null && statusPill!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DealOneTokens.softTileBgOf(context),
                    borderRadius: AppRadii.full,
                    border: Border.all(color: DealOneTokens.cardBorderOf(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: DealOneTokens.textPrimaryOf(context),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusPill!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DealOneTokens.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: DealOneTokens.buttonMinHeight,
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DealOneTokens.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
                        ),
                      ),
                      onPressed: onAction,
                      icon: Icon(
                        actionIcon ?? Icons.explore_outlined,
                        size: 20,
                      ),
                      label: Text(
                        actionLabel!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (footerText != null && footerText!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        footerText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: DealOneTokens.textSecondaryOf(context),
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
    );
  }
}

/// Reusable Deal One error view with offline awareness and retry CTA.
class DealOneErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const DealOneErrorStateView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final presented = ErrorPresenter.present(error, isArabic: isArabic);
    return DealOneEmptyStateView(
      icon: presented.kind == FeatureErrorKind.offline
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      title: presented.title,
      description: presented.message,
      actionLabel: presented.canRetry
          ? (isArabic ? 'إعادة المحاولة' : 'Try Again')
          : null,
      actionIcon: Icons.refresh_rounded,
      onAction: presented.canRetry ? onRetry : null,
    );
  }
}

/// Reusable Deal One skeleton list for smooth loading states.
class DealOneLoadingList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const DealOneLoadingList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = context.horizontalScreenPadding;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, _) => Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: DealOneTokens.softTileBgOf(context),
          borderRadius: AppRadii.lg,
        ),
      ),
    );
  }
}

/// Subtle privacy/encryption footer matching Conversations & Notification PNGs.
class DealOnePrivacyFooter extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showCircleLock;

  const DealOnePrivacyFooter({
    super.key,
    required this.title,
    this.subtitle,
    this.showCircleLock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCircleLock) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DealOneTokens.softTileBgOf(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: DealOneTokens.textPrimaryOf(context),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
              ),
            ],
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: DealOneTokens.textSecondaryOf(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: DealOneTokens.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
