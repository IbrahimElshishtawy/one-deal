import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';

/// Notification card matching `Notification.png`:
/// Unread cards feature a navy start accent bar, solid navy icon box, and unread dot.
class NotificationItemCard extends StatelessWidget {
  final UserNotificationEntity notification;
  final VoidCallback onTap;

  const NotificationItemCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _resolveIcon() {
    final t = notification.type.toLowerCase();
    if (t.contains('booking') || t.contains('viewing')) {
      return Icons.event_available_rounded;
    }
    if (t.contains('chat') || t.contains('message')) {
      return Icons.chat_bubble_rounded;
    }
    if (t.contains('price') || t.contains('favorite')) {
      return Icons.local_offer_outlined;
    }
    if (t.contains('account') || t.contains('business')) {
      return Icons.storefront_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  String? _actionLabel(bool isArabic) {
    if (notification.bookingId != null) {
      return isArabic ? 'عرض تفاصيل الموعد' : 'View Appointment';
    }
    if (notification.conversationId != null) {
      return isArabic ? 'فتح المحادثة' : 'Open Chat';
    }
    if (notification.listingId != null) {
      return isArabic ? 'عرض العقار' : 'View Property';
    }
    return null;
  }

  String _formatTime(DateTime dt, bool isArabic) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Now';
    if (diff.inMinutes < 60) {
      return isArabic
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    }
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12
        ? (isArabic ? 'م' : 'PM')
        : (isArabic ? 'ص' : 'AM');
    if (diff.inDays == 1) {
      return isArabic ? 'أمس $h:$m $period' : 'Yesterday $h:$m $period';
    }
    return '${dt.day}/${dt.month} $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final unread = !notification.isRead;
    final actionText = _actionLabel(isArabic);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lg,
        child: Container(
          decoration: DealOneTokens.cardDecoration(context),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (unread)
                  Container(width: 4, color: DealOneTokens.navy),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: unread
                                ? DealOneTokens.navy
                                : DealOneTokens.cardSurfaceOf(context),
                            borderRadius: AppRadii.md,
                            border: unread
                                ? null
                                : Border.all(
                                    color: DealOneTokens.cardBorderOf(context),
                                  ),
                          ),
                          child: Icon(
                            _resolveIcon(),
                            size: 21,
                            color: unread
                                ? Colors.white
                                : DealOneTokens.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            notification.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  DealOneTokens.textPrimaryOf(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (unread) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: DealOneTokens.navy,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _formatTime(
                                      notification.createdAt,
                                      isArabic,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: DealOneTokens.textSecondaryOf(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.body,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.45,
                                  color: DealOneTokens.textSecondaryOf(context),
                                ),
                              ),
                              if (actionText != null ||
                                  notification.locationLabel != null ||
                                  notification.discountBadge != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (actionText != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: DealOneTokens.softTileBgOf(
                                            context,
                                          ),
                                          borderRadius: AppRadii.sm,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              actionText,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    DealOneTokens.textPrimaryOf(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 16,
                                              color:
                                                  DealOneTokens.textPrimaryOf(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (notification.locationLabel != null &&
                                        notification.locationLabel!.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 15,
                                            color: DealOneTokens.amber,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            notification.locationLabel!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: DealOneTokens.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (notification.discountBadge != null &&
                                        notification.discountBadge!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: DealOneTokens.amberTintOf(
                                            context,
                                          ),
                                          borderRadius: AppRadii.full,
                                        ),
                                        child: Text(
                                          notification.discountBadge!,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: DealOneTokens.successGreen,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
