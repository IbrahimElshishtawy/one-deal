import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/design_system/deal_one_ui_states.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/core/utils/responsive_utils.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';
import 'package:market_space/features/conversations/presentation/providers/chat_settings_provider.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_color_theme_picker.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_settings_preview_card.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_settings_section_card.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_settings_slider_tile.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_settings_toggle_tile.dart';
import 'package:market_space/features/conversations/presentation/widgets/settings/chat_wallpaper_picker.dart';

/// Telegram-inspired Chat Settings page with live interactive preview,
/// color themes, wallpapers, bubble geometry, typography, and behavior toggles.
class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final hPad = context.horizontalScreenPadding;
    final settings = ref.watch(chatSettingsProvider);
    final notifier = ref.read(chatSettingsProvider.notifier);
    final accent = settings.colorTheme.accent(isDark);

    return Scaffold(
      backgroundColor: DealOneTokens.pageBgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            DealOneSubPageHeader(
              title: isArabic ? 'إعدادات الدردشة' : 'Chat Settings',
              subtitle: isArabic
                  ? 'تخصيص المظهر والفقاعات وسلوك الإرسال'
                  : 'Customize appearance, bubbles & messaging behavior',
              onBack: () {
                if (context.canPop()) context.pop();
              },
              trailing: TextButton.icon(
                key: const Key('chat_settings_reset_button'),
                onPressed: () {
                  notifier.resetToDefaults();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تمت استعادة الإعدادات الافتراضية'
                            : 'Chat settings reset to defaults',
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.restart_alt_rounded, size: 18, color: accent),
                label: Text(
                  isArabic ? 'استعادة' : 'Reset',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  hPad,
                  AppSpacing.sm,
                  hPad,
                  AppSpacing.xxl,
                ),
                children: [
                  ChatSettingsPreviewCard(settings: settings),
                  const SizedBox(height: AppSpacing.lg),
                  ChatSettingsSectionCard(
                    title: isArabic ? 'سمة الألوان' : 'Color Theme',
                    colorTheme: settings.colorTheme,
                    children: [
                      ChatColorThemePicker(
                        selectedTheme: settings.colorTheme,
                        onSelected: notifier.setColorTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ChatSettingsSectionCard(
                    title: isArabic ? 'خلفية المحادثة' : 'Chat Wallpaper',
                    colorTheme: settings.colorTheme,
                    children: [
                      ChatWallpaperPicker(
                        selectedWallpaper: settings.wallpaper,
                        colorTheme: settings.colorTheme,
                        onSelected: notifier.setWallpaper,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ChatSettingsSectionCard(
                    title: isArabic
                        ? 'حجم النص وشكل الفقاعات'
                        : 'Text Size & Message Corners',
                    colorTheme: settings.colorTheme,
                    children: [
                      ChatSettingsSliderTile(
                        sliderKey: const Key('chat_font_size_slider'),
                        icon: Icons.text_fields_rounded,
                        title: isArabic ? 'حجم نص الرسائل' : 'Message text size',
                        valueLabel: '${settings.fontSize.round()} px',
                        value: settings.fontSize,
                        min: ChatSettingsEntity.minFontSize,
                        max: ChatSettingsEntity.maxFontSize,
                        divisions: 10,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setFontSize,
                      ),
                      ChatSettingsSliderTile(
                        sliderKey: const Key('chat_bubble_radius_slider'),
                        icon: Icons.rounded_corner_rounded,
                        title: isArabic
                            ? 'انحناء زوايا الفقاعات'
                            : 'Message corners',
                        valueLabel: '${settings.bubbleRadius.round()} px',
                        value: settings.bubbleRadius,
                        min: ChatSettingsEntity.minBubbleRadius,
                        max: ChatSettingsEntity.maxBubbleRadius,
                        divisions: 9,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setBubbleRadius,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_compact_mode_switch'),
                        icon: Icons.view_compact_alt_outlined,
                        title: isArabic ? 'الوضع المضغوط' : 'Compact view',
                        subtitle: isArabic
                            ? 'تقليل المسافات لعرض رسائل أكثر'
                            : 'Tighter spacing to show more messages',
                        value: settings.compactMode,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setCompactMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ChatSettingsSectionCard(
                    title: isArabic ? 'تفاصيل العرض' : 'Chat Display',
                    colorTheme: settings.colorTheme,
                    children: [
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_timestamps_switch'),
                        icon: Icons.access_time_rounded,
                        title: isArabic
                            ? 'إظهار وقت الرسائل'
                            : 'Show timestamps',
                        subtitle: isArabic
                            ? 'عرض التوقيت أسفل كل رسالة'
                            : 'Display send time inside message bubbles',
                        value: settings.showTimestamps,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setShowTimestamps,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_read_receipts_switch'),
                        icon: Icons.done_all_rounded,
                        title: isArabic
                            ? 'علامات الاستلام والقراءة'
                            : 'Read receipts',
                        subtitle: isArabic
                            ? 'إظهار علامات الإرسال والقراءة على رسائلك'
                            : 'Show sent & read checkmarks on outgoing messages',
                        value: settings.showReadReceipts,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setShowReadReceipts,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_listing_banner_switch'),
                        icon: Icons.home_work_outlined,
                        title: isArabic
                            ? 'بطاقة الإعلان المثبتة'
                            : 'Pinned listing banner',
                        subtitle: isArabic
                            ? 'عرض تفاصيل العقار أو الإعلان أعلى الدردشة'
                            : 'Show associated listing preview at the top',
                        value: settings.showListingBanner,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setShowListingBanner,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_quick_replies_switch'),
                        icon: Icons.bolt_rounded,
                        title: isArabic
                            ? 'الردود السريعة الجاهزة'
                            : 'Quick reply suggestions',
                        subtitle: isArabic
                            ? 'شريط اقتراحات سريع فوق حقل الكتابة'
                            : 'Show one-tap reply chips above composer',
                        value: settings.showQuickReplies,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setShowQuickReplies,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ChatSettingsSectionCard(
                    title: isArabic ? 'سلوك الإرسال والتفاعل' : 'Behavior',
                    colorTheme: settings.colorTheme,
                    children: [
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_send_by_enter_switch'),
                        icon: Icons.keyboard_return_rounded,
                        title: isArabic
                            ? 'الإرسال بزر الإدخال (Enter)'
                            : 'Send by Enter',
                        subtitle: isArabic
                            ? 'إرسال الرسالة مباشرة عند الضغط على زر الإدخال'
                            : 'Press Enter/Send key on keyboard to send',
                        value: settings.sendByEnter,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setSendByEnter,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_haptic_switch'),
                        icon: Icons.vibration_rounded,
                        title: isArabic
                            ? 'الاهتزاز الخفيف عند التفاعل'
                            : 'Haptic feedback',
                        subtitle: isArabic
                            ? 'استجابة لمسية عند الإرسال أو الضغط المطول'
                            : 'Subtle vibration on send & message actions',
                        value: settings.hapticFeedback,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setHapticFeedback,
                      ),
                      ChatSettingsToggleTile(
                        switchKey: const Key('chat_autoscroll_switch'),
                        icon: Icons.vertical_align_bottom_rounded,
                        title: isArabic
                            ? 'التمرير التلقائي لآخر رسالة'
                            : 'Auto-scroll to latest',
                        subtitle: isArabic
                            ? 'الانتقال تلقائياً لأسفل عند إرسال رسالة جديدة'
                            : 'Jump to the bottom automatically after sending',
                        value: settings.autoScrollToBottom,
                        colorTheme: settings.colorTheme,
                        onChanged: notifier.setAutoScrollToBottom,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
