import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/core/storage/storage_keys.dart';
import 'package:market_space/features/conversations/domain/entities/chat_settings_entity.dart';

class ChatSettingsNotifier extends Notifier<ChatSettingsEntity> {
  bool _disposed = false;
  bool _mutatedBeforeLoad = false;

  @override
  ChatSettingsEntity build() {
    _disposed = false;
    _mutatedBeforeLoad = false;
    ref.onDispose(() {
      _disposed = true;
    });
    Future.microtask(_load);
    return ChatSettingsEntity.defaults;
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      final raw = await prefs.getString(StorageKeys.chatSettings);
      if (_disposed || _mutatedBeforeLoad || raw == null || raw.isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        state = ChatSettingsEntity.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // Keep default settings if stored JSON is corrupted.
    }
  }

  void _update(ChatSettingsEntity next) {
    _mutatedBeforeLoad = true;
    state = next;
    unawaited(_persist(next));
  }

  Future<void> _persist(ChatSettingsEntity value) async {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setString(
        StorageKeys.chatSettings,
        jsonEncode(value.toJson()),
      );
    } catch (_) {
      // Persistence failure should not break live UI state.
    }
  }

  void setFontSize(double value) => _update(state.copyWith(fontSize: value));

  void setBubbleRadius(double value) =>
      _update(state.copyWith(bubbleRadius: value));

  void setColorTheme(ChatColorTheme theme) =>
      _update(state.copyWith(colorTheme: theme));

  void setWallpaper(ChatWallpaperPreset wallpaper) =>
      _update(state.copyWith(wallpaper: wallpaper));

  void setSendByEnter(bool value) =>
      _update(state.copyWith(sendByEnter: value));

  void setShowTimestamps(bool value) =>
      _update(state.copyWith(showTimestamps: value));

  void setShowReadReceipts(bool value) =>
      _update(state.copyWith(showReadReceipts: value));

  void setShowListingBanner(bool value) =>
      _update(state.copyWith(showListingBanner: value));

  void setShowQuickReplies(bool value) =>
      _update(state.copyWith(showQuickReplies: value));

  void setCompactMode(bool value) =>
      _update(state.copyWith(compactMode: value));

  void setHapticFeedback(bool value) =>
      _update(state.copyWith(hapticFeedback: value));

  void setAutoScrollToBottom(bool value) =>
      _update(state.copyWith(autoScrollToBottom: value));

  void toggleMuteConversation(String conversationId) {
    final nextSet = Set<String>.from(state.mutedConversationIds);
    if (nextSet.contains(conversationId)) {
      nextSet.remove(conversationId);
    } else {
      nextSet.add(conversationId);
    }
    _update(state.copyWith(mutedConversationIds: nextSet));
  }

  void togglePinConversation(String conversationId) {
    final nextPinned = Set<String>.from(state.pinnedConversationIds);
    if (nextPinned.contains(conversationId)) {
      nextPinned.remove(conversationId);
    } else {
      nextPinned.add(conversationId);
    }
    _update(state.copyWith(pinnedConversationIds: nextPinned));
  }

  void toggleArchiveConversation(String conversationId) {
    final nextArchived = Set<String>.from(state.archivedConversationIds);
    final nextPinned = Set<String>.from(state.pinnedConversationIds);
    if (nextArchived.contains(conversationId)) {
      nextArchived.remove(conversationId);
    } else {
      nextArchived.add(conversationId);
      nextPinned.remove(conversationId);
    }
    _update(
      state.copyWith(
        archivedConversationIds: nextArchived,
        pinnedConversationIds: nextPinned,
      ),
    );
  }

  void setSwipeAction(ChatListSwipeAction action) =>
      _update(state.copyWith(swipeAction: action));

  void setChatListTwoLines(bool value) =>
      _update(state.copyWith(chatListTwoLines: value));

  void setShowListingTagInInbox(bool value) =>
      _update(state.copyWith(showListingTagInInbox: value));

  void setShowAdvisorBanner(bool value) =>
      _update(state.copyWith(showAdvisorBanner: value));

  void resetToDefaults() => _update(ChatSettingsEntity.defaults);
}

final chatSettingsProvider =
    NotifierProvider<ChatSettingsNotifier, ChatSettingsEntity>(
      ChatSettingsNotifier.new,
    );
