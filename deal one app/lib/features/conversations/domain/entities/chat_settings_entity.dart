import 'package:flutter/material.dart';

/// Telegram-inspired color themes for chat bubbles and accent controls.
enum ChatColorTheme {
  dealOneNavy,
  telegramBlue,
  emerald,
  violet,
  amber,
  crimson,
}

extension ChatColorThemeX on ChatColorTheme {
  Color outgoingStart(bool isDark) {
    switch (this) {
      case ChatColorTheme.dealOneNavy:
        return isDark ? const Color(0xFF233B63) : const Color(0xFF1B2B48);
      case ChatColorTheme.telegramBlue:
        return isDark ? const Color(0xFF2B6CB0) : const Color(0xFF2AABEE);
      case ChatColorTheme.emerald:
        return isDark ? const Color(0xFF166534) : const Color(0xFF15803D);
      case ChatColorTheme.violet:
        return isDark ? const Color(0xFF5B21B6) : const Color(0xFF7C3AED);
      case ChatColorTheme.amber:
        return isDark ? const Color(0xFF9A3412) : const Color(0xFFD97706);
      case ChatColorTheme.crimson:
        return isDark ? const Color(0xFF9F1239) : const Color(0xFFE11D48);
    }
  }

  Color outgoingEnd(bool isDark) {
    switch (this) {
      case ChatColorTheme.dealOneNavy:
        return isDark ? const Color(0xFF162744) : const Color(0xFF2C446E);
      case ChatColorTheme.telegramBlue:
        return isDark ? const Color(0xFF1D4ED8) : const Color(0xFF1E88E5);
      case ChatColorTheme.emerald:
        return isDark ? const Color(0xFF14532D) : const Color(0xFF16A34A);
      case ChatColorTheme.violet:
        return isDark ? const Color(0xFF4C1D95) : const Color(0xFF6D28D9);
      case ChatColorTheme.amber:
        return isDark ? const Color(0xFF7C2D12) : const Color(0xFFB45309);
      case ChatColorTheme.crimson:
        return isDark ? const Color(0xFF881337) : const Color(0xFFBE123C);
    }
  }

  Color accent(bool isDark) {
    switch (this) {
      case ChatColorTheme.dealOneNavy:
        return isDark ? const Color(0xFF5B8DEF) : const Color(0xFF1B2B48);
      case ChatColorTheme.telegramBlue:
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF229ED9);
      case ChatColorTheme.emerald:
        return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
      case ChatColorTheme.violet:
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
      case ChatColorTheme.amber:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case ChatColorTheme.crimson:
        return isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    }
  }

  String label(bool isArabic) {
    switch (this) {
      case ChatColorTheme.dealOneNavy:
        return isArabic ? 'كحلي ديل ون' : 'Deal One';
      case ChatColorTheme.telegramBlue:
        return isArabic ? 'أزرق تليجرام' : 'Telegram';
      case ChatColorTheme.emerald:
        return isArabic ? 'زمردي' : 'Emerald';
      case ChatColorTheme.violet:
        return isArabic ? 'بنفسجي' : 'Violet';
      case ChatColorTheme.amber:
        return isArabic ? 'كهرماني' : 'Amber';
      case ChatColorTheme.crimson:
        return isArabic ? 'ياقوتي' : 'Crimson';
    }
  }
}

/// Telegram-inspired chat background wallpaper presets.
enum ChatWallpaperPreset {
  solid,
  geometricDoodle,
  midnightAurora,
  oceanDusk,
  warmSand,
  emeraldMist,
}

extension ChatWallpaperPresetX on ChatWallpaperPreset {
  bool get hasPattern => this != ChatWallpaperPreset.solid;

  List<Color> gradientColors(bool isDark) {
    switch (this) {
      case ChatWallpaperPreset.solid:
        return isDark
            ? const [Color(0xFF0E1117), Color(0xFF12161F)]
            : const [Color(0xFFF4F6FA), Color(0xFFF4F6FA)];
      case ChatWallpaperPreset.geometricDoodle:
        return isDark
            ? const [Color(0xFF0F1623), Color(0xFF162032), Color(0xFF0E141F)]
            : const [Color(0xFFE9EFF8), Color(0xFFF3F6FC), Color(0xFFE6EDF7)];
      case ChatWallpaperPreset.midnightAurora:
        return isDark
            ? const [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF1F1638)]
            : const [Color(0xFFE0ECFF), Color(0xFFEDE9FE), Color(0xFFE2F1F8)];
      case ChatWallpaperPreset.oceanDusk:
        return isDark
            ? const [Color(0xFF0A192F), Color(0xFF112240), Color(0xFF0D2B3E)]
            : const [Color(0xFFDCEEFB), Color(0xFFE6F4FA), Color(0xFFD4E9F7)];
      case ChatWallpaperPreset.warmSand:
        return isDark
            ? const [Color(0xFF1E1914), Color(0xFF272018), Color(0xFF1A1511)]
            : const [Color(0xFFFDF5E8), Color(0xFFFAF0DF), Color(0xFFF6E7CE)];
      case ChatWallpaperPreset.emeraldMist:
        return isDark
            ? const [Color(0xFF0C1D16), Color(0xFF12281F), Color(0xFF0A1712)]
            : const [Color(0xFFE4F7EC), Color(0xFFECFBF2), Color(0xFFDDF3E6)];
    }
  }

  String label(bool isArabic) {
    switch (this) {
      case ChatWallpaperPreset.solid:
        return isArabic ? 'سادة' : 'Solid';
      case ChatWallpaperPreset.geometricDoodle:
        return isArabic ? 'نقشة تليجرام' : 'Doodle';
      case ChatWallpaperPreset.midnightAurora:
        return isArabic ? 'شفق ليلي' : 'Aurora';
      case ChatWallpaperPreset.oceanDusk:
        return isArabic ? 'محيط هادئ' : 'Ocean';
      case ChatWallpaperPreset.warmSand:
        return isArabic ? 'رمال دافئة' : 'Sand';
      case ChatWallpaperPreset.emeraldMist:
        return isArabic ? 'ضباب زمردي' : 'Emerald';
    }
  }
}

/// Telegram-style swipe gesture action on conversation list items.
enum ChatListSwipeAction { pin, mute, archive }

extension ChatListSwipeActionX on ChatListSwipeAction {
  String label(bool isArabic) {
    switch (this) {
      case ChatListSwipeAction.pin:
        return isArabic ? 'تثبيت' : 'Pin';
      case ChatListSwipeAction.mute:
        return isArabic ? 'كتم' : 'Mute';
      case ChatListSwipeAction.archive:
        return isArabic ? 'أرشفة' : 'Archive';
    }
  }

  IconData get icon {
    switch (this) {
      case ChatListSwipeAction.pin:
        return Icons.push_pin_rounded;
      case ChatListSwipeAction.mute:
        return Icons.notifications_off_rounded;
      case ChatListSwipeAction.archive:
        return Icons.archive_rounded;
    }
  }

  Color color(bool isDark, ChatColorTheme theme) {
    switch (this) {
      case ChatListSwipeAction.pin:
        return theme.accent(isDark);
      case ChatListSwipeAction.mute:
        return const Color(0xFFD97706);
      case ChatListSwipeAction.archive:
        return isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    }
  }
}

/// Persistent user-configurable Telegram-style chat settings.
class ChatSettingsEntity {
  static const double minFontSize = 12.0;
  static const double maxFontSize = 22.0;
  static const double minBubbleRadius = 6.0;
  static const double maxBubbleRadius = 24.0;

  final double fontSize;
  final double bubbleRadius;
  final ChatColorTheme colorTheme;
  final ChatWallpaperPreset wallpaper;
  final bool sendByEnter;
  final bool showTimestamps;
  final bool showReadReceipts;
  final bool showListingBanner;
  final bool showQuickReplies;
  final bool compactMode;
  final bool hapticFeedback;
  final bool autoScrollToBottom;
  final Set<String> mutedConversationIds;
  final Set<String> pinnedConversationIds;
  final Set<String> archivedConversationIds;
  final ChatListSwipeAction swipeAction;
  final bool chatListTwoLines;
  final bool showListingTagInInbox;
  final bool showAdvisorBanner;

  const ChatSettingsEntity({
    this.fontSize = 15.0,
    this.bubbleRadius = 18.0,
    this.colorTheme = ChatColorTheme.dealOneNavy,
    this.wallpaper = ChatWallpaperPreset.geometricDoodle,
    this.sendByEnter = true,
    this.showTimestamps = true,
    this.showReadReceipts = true,
    this.showListingBanner = true,
    this.showQuickReplies = true,
    this.compactMode = false,
    this.hapticFeedback = true,
    this.autoScrollToBottom = true,
    this.mutedConversationIds = const {},
    this.pinnedConversationIds = const {},
    this.archivedConversationIds = const {},
    this.swipeAction = ChatListSwipeAction.pin,
    this.chatListTwoLines = false,
    this.showListingTagInInbox = true,
    this.showAdvisorBanner = true,
  });

  static const ChatSettingsEntity defaults = ChatSettingsEntity();

  bool isMuted(String conversationId) =>
      mutedConversationIds.contains(conversationId);

  bool isPinned(String conversationId) =>
      pinnedConversationIds.contains(conversationId);

  bool isArchived(String conversationId) =>
      archivedConversationIds.contains(conversationId);

  ChatSettingsEntity copyWith({
    double? fontSize,
    double? bubbleRadius,
    ChatColorTheme? colorTheme,
    ChatWallpaperPreset? wallpaper,
    bool? sendByEnter,
    bool? showTimestamps,
    bool? showReadReceipts,
    bool? showListingBanner,
    bool? showQuickReplies,
    bool? compactMode,
    bool? hapticFeedback,
    bool? autoScrollToBottom,
    Set<String>? mutedConversationIds,
    Set<String>? pinnedConversationIds,
    Set<String>? archivedConversationIds,
    ChatListSwipeAction? swipeAction,
    bool? chatListTwoLines,
    bool? showListingTagInInbox,
    bool? showAdvisorBanner,
  }) {
    return ChatSettingsEntity(
      fontSize: (fontSize ?? this.fontSize).clamp(minFontSize, maxFontSize),
      bubbleRadius: (bubbleRadius ?? this.bubbleRadius).clamp(
        minBubbleRadius,
        maxBubbleRadius,
      ),
      colorTheme: colorTheme ?? this.colorTheme,
      wallpaper: wallpaper ?? this.wallpaper,
      sendByEnter: sendByEnter ?? this.sendByEnter,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showListingBanner: showListingBanner ?? this.showListingBanner,
      showQuickReplies: showQuickReplies ?? this.showQuickReplies,
      compactMode: compactMode ?? this.compactMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      autoScrollToBottom: autoScrollToBottom ?? this.autoScrollToBottom,
      mutedConversationIds:
          mutedConversationIds ?? this.mutedConversationIds,
      pinnedConversationIds:
          pinnedConversationIds ?? this.pinnedConversationIds,
      archivedConversationIds:
          archivedConversationIds ?? this.archivedConversationIds,
      swipeAction: swipeAction ?? this.swipeAction,
      chatListTwoLines: chatListTwoLines ?? this.chatListTwoLines,
      showListingTagInInbox:
          showListingTagInInbox ?? this.showListingTagInInbox,
      showAdvisorBanner: showAdvisorBanner ?? this.showAdvisorBanner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'bubbleRadius': bubbleRadius,
      'colorTheme': colorTheme.name,
      'wallpaper': wallpaper.name,
      'sendByEnter': sendByEnter,
      'showTimestamps': showTimestamps,
      'showReadReceipts': showReadReceipts,
      'showListingBanner': showListingBanner,
      'showQuickReplies': showQuickReplies,
      'compactMode': compactMode,
      'hapticFeedback': hapticFeedback,
      'autoScrollToBottom': autoScrollToBottom,
      'mutedConversationIds': mutedConversationIds.toList(),
      'pinnedConversationIds': pinnedConversationIds.toList(),
      'archivedConversationIds': archivedConversationIds.toList(),
      'swipeAction': swipeAction.name,
      'chatListTwoLines': chatListTwoLines,
      'showListingTagInInbox': showListingTagInInbox,
      'showAdvisorBanner': showAdvisorBanner,
    };
  }

  factory ChatSettingsEntity.fromJson(Map<String, dynamic> json) {
    final rawFont = json['fontSize'];
    final parsedFont = rawFont is num
        ? rawFont.toDouble().clamp(minFontSize, maxFontSize)
        : defaults.fontSize;

    final rawRadius = json['bubbleRadius'];
    final parsedRadius = rawRadius is num
        ? rawRadius.toDouble().clamp(minBubbleRadius, maxBubbleRadius)
        : defaults.bubbleRadius;

    final themeName = json['colorTheme']?.toString();
    final parsedTheme = ChatColorTheme.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => defaults.colorTheme,
    );

    final wallpaperName = json['wallpaper']?.toString();
    final parsedWallpaper = ChatWallpaperPreset.values.firstWhere(
      (w) => w.name == wallpaperName,
      orElse: () => defaults.wallpaper,
    );

    final swipeName = json['swipeAction']?.toString();
    final parsedSwipe = ChatListSwipeAction.values.firstWhere(
      (s) => s.name == swipeName,
      orElse: () => defaults.swipeAction,
    );

    Set<String> parseIdSet(dynamic raw) => raw is List
        ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet()
        : const <String>{};

    return ChatSettingsEntity(
      fontSize: parsedFont,
      bubbleRadius: parsedRadius,
      colorTheme: parsedTheme,
      wallpaper: parsedWallpaper,
      sendByEnter: json['sendByEnter'] is bool
          ? json['sendByEnter'] as bool
          : defaults.sendByEnter,
      showTimestamps: json['showTimestamps'] is bool
          ? json['showTimestamps'] as bool
          : defaults.showTimestamps,
      showReadReceipts: json['showReadReceipts'] is bool
          ? json['showReadReceipts'] as bool
          : defaults.showReadReceipts,
      showListingBanner: json['showListingBanner'] is bool
          ? json['showListingBanner'] as bool
          : defaults.showListingBanner,
      showQuickReplies: json['showQuickReplies'] is bool
          ? json['showQuickReplies'] as bool
          : defaults.showQuickReplies,
      compactMode: json['compactMode'] is bool
          ? json['compactMode'] as bool
          : defaults.compactMode,
      hapticFeedback: json['hapticFeedback'] is bool
          ? json['hapticFeedback'] as bool
          : defaults.hapticFeedback,
      autoScrollToBottom: json['autoScrollToBottom'] is bool
          ? json['autoScrollToBottom'] as bool
          : defaults.autoScrollToBottom,
      mutedConversationIds: parseIdSet(json['mutedConversationIds']),
      pinnedConversationIds: parseIdSet(json['pinnedConversationIds']),
      archivedConversationIds: parseIdSet(json['archivedConversationIds']),
      swipeAction: parsedSwipe,
      chatListTwoLines: json['chatListTwoLines'] is bool
          ? json['chatListTwoLines'] as bool
          : defaults.chatListTwoLines,
      showListingTagInInbox: json['showListingTagInInbox'] is bool
          ? json['showListingTagInInbox'] as bool
          : defaults.showListingTagInInbox,
      showAdvisorBanner: json['showAdvisorBanner'] is bool
          ? json['showAdvisorBanner'] as bool
          : defaults.showAdvisorBanner,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatSettingsEntity) return false;
    return other.fontSize == fontSize &&
        other.bubbleRadius == bubbleRadius &&
        other.colorTheme == colorTheme &&
        other.wallpaper == wallpaper &&
        other.sendByEnter == sendByEnter &&
        other.showTimestamps == showTimestamps &&
        other.showReadReceipts == showReadReceipts &&
        other.showListingBanner == showListingBanner &&
        other.showQuickReplies == showQuickReplies &&
        other.compactMode == compactMode &&
        other.hapticFeedback == hapticFeedback &&
        other.autoScrollToBottom == autoScrollToBottom &&
        _setEquals(other.mutedConversationIds, mutedConversationIds) &&
        _setEquals(other.pinnedConversationIds, pinnedConversationIds) &&
        _setEquals(other.archivedConversationIds, archivedConversationIds) &&
        other.swipeAction == swipeAction &&
        other.chatListTwoLines == chatListTwoLines &&
        other.showListingTagInInbox == showListingTagInInbox &&
        other.showAdvisorBanner == showAdvisorBanner;
  }

  @override
  int get hashCode => Object.hash(
    fontSize,
    bubbleRadius,
    colorTheme,
    wallpaper,
    sendByEnter,
    showTimestamps,
    showReadReceipts,
    showListingBanner,
    showQuickReplies,
    compactMode,
    hapticFeedback,
    autoScrollToBottom,
    Object.hashAllUnordered(mutedConversationIds),
    Object.hashAllUnordered(pinnedConversationIds),
    Object.hashAllUnordered(archivedConversationIds),
    swipeAction,
    chatListTwoLines,
    showListingTagInInbox,
    showAdvisorBanner,
  );

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
