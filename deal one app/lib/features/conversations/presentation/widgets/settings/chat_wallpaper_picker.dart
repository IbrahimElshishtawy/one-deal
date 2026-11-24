import 'package:flutter/material.dart';
import 'package:market_space/core/design_system/deal_one_design_tokens.dart';
import 'package:market_space/core/theme/app_colors.dart';
import 'package:market_space/core/theme/app_radii.dart';
import 'package:market_space/core/theme/app_spacing.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

/// Telegram-style horizontal wallpaper preset picker.
class ChatWallpaperPicker extends StatelessWidget {
  final ChatWallpaperPreset selectedWallpaper;
  final ChatColorTheme colorTheme;
  final ValueChanged<ChatWallpaperPreset> onSelected;

  const ChatWallpaperPicker({
    super.key,
    required this.selectedWallpaper,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final accent = colorTheme.accent(isDark);

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: ChatWallpaperPreset.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final preset = ChatWallpaperPreset.values[index];
          final selected = preset == selectedWallpaper;
          final gradient = preset.gradientColors(isDark);

          return InkWell(
            key: Key('chat_wallpaper_option_${preset.name}'),
            borderRadius: AppRadii.md,
            onTap: () => onSelected(preset),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: AppRadii.md,
                      border: Border.all(
                        color: selected
                            ? accent
                            : DealOneTokens.cardBorderOf(context),
                        width: selected ? 2.4 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (preset.hasPattern)
                          Center(
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              size: 20,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : DealOneTokens.navy.withValues(alpha: 0.28),
                            ),
                          ),
                        if (selected)
                          PositionedDirectional(
                            top: 5,
                            end: 5,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: accent,
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  preset.label(isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? accent
                        : DealOneTokens.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
