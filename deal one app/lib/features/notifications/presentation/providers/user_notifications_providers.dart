import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_space/core/providers/core_providers.dart';
import 'package:market_space/features/notifications/data/repositories/user_notifications_repository_impl.dart';
import 'package:market_space/features/notifications/domain/entities/user_notification_entity.dart';
import 'package:market_space/features/notifications/domain/repositories/user_notifications_repository.dart';

enum NotificationCategoryFilter { all, propertiesAndViewings, chats }

final userNotificationsRepositoryProvider =
    Provider<UserNotificationsRepository>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return UserNotificationsRepositoryImpl(apiClient: apiClient);
    });

class UserNotificationsState {
  final List<UserNotificationEntity> items;
  final int unreadCount;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMarkingAll;
  final Object? error;
  final NotificationCategoryFilter filter;

  const UserNotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isMarkingAll = false,
    this.error,
    this.filter = NotificationCategoryFilter.all,
  });

  List<UserNotificationEntity> get filteredItems {
    switch (filter) {
      case NotificationCategoryFilter.all:
        return items;
      case NotificationCategoryFilter.propertiesAndViewings:
        return items.where((n) => n.isPropertyOrViewingType).toList();
      case NotificationCategoryFilter.chats:
        return items.where((n) => n.isChatType).toList();
    }
  }

  UserNotificationsState copyWith({
    List<UserNotificationEntity>? items,
    int? unreadCount,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMarkingAll,
    Object? error,
    bool clearError = false,
    NotificationCategoryFilter? filter,
  }) {
    return UserNotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAll: isMarkingAll ?? this.isMarkingAll,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

class UserNotificationsController
    extends StateNotifier<UserNotificationsState> {
  final Ref _ref;

  UserNotificationsController(this._ref)
      : super(const UserNotificationsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    final session = _ref.read(sessionProvider);
    if (!session.isAuthenticated) {
      state = const UserNotificationsState();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ref
          .read(userNotificationsRepositoryProvider)
          .getNotifications(page: 1, limit: 20);
      state = state.copyWith(
        items: result.items,
        unreadCount: result.unreadCount,
        page: result.page,
        hasMore: result.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await _ref
          .read(userNotificationsRepositoryProvider)
          .getNotifications(page: nextPage, limit: 20);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        unreadCount: result.unreadCount,
        page: result.page,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setFilter(NotificationCategoryFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> markAsRead(String notificationId) async {
    final targetIndex = state.items.indexWhere((n) => n.id == notificationId);
    if (targetIndex == -1 || state.items[targetIndex].isRead) return;

    final updated = List<UserNotificationEntity>.from(state.items);
    updated[targetIndex] = updated[targetIndex].copyWith(isRead: true);
    final nextUnread = (state.unreadCount - 1).clamp(0, 999999);
    state = state.copyWith(items: updated, unreadCount: nextUnread);

    try {
      await _ref
          .read(userNotificationsRepositoryProvider)
          .markAsRead(notificationId);
    } catch (_) {
      await loadInitial();
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0 || state.isMarkingAll) return;
    state = state.copyWith(isMarkingAll: true);
    try {
      await _ref.read(userNotificationsRepositoryProvider).markAllAsRead();
      state = state.copyWith(
        items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
        isMarkingAll: false,
      );
    } catch (e) {
      state = state.copyWith(isMarkingAll: false, error: e);
    }
  }
}

final userNotificationsProvider = StateNotifierProvider<
  UserNotificationsController,
  UserNotificationsState
>((ref) {
  ref.watch(sessionProvider);
  return UserNotificationsController(ref);
});
