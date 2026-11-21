import 'package:flutter/foundation.dart';

import 'package:market_space/core/notifications/data/models/app_notification.dart';

abstract class NotificationRepository {
  List<AppNotification> getNotificationsForSection(String sectionId);
  int getUnreadCountForSection(String sectionId);
  Map<String, int> getAllUnreadCounts();
  void markAsRead(String notificationId);
  void markAllAsReadForSection(String sectionId);
  void addNotification(AppNotification notification);
  ValueNotifier<Map<String, int>> get unreadCountsNotifier;
}

class NotificationRepositoryImpl implements NotificationRepository {
  final List<AppNotification> _notifications = [];
  final ValueNotifier<Map<String, int>> _unreadCountsNotifier = ValueNotifier(
    {},
  );

  NotificationRepositoryImpl({List<AppNotification>? initialNotifications}) {
    _notifications.addAll(initialNotifications ?? _getMockNotifications());
    _updateUnreadCounts();
  }

  @override
  ValueNotifier<Map<String, int>> get unreadCountsNotifier =>
      _unreadCountsNotifier;

  @override
  List<AppNotification> getNotificationsForSection(String sectionId) {
    return _notifications.where((n) => n.sectionId == sectionId).toList();
  }

  @override
  int getUnreadCountForSection(String sectionId) {
    return _notifications
        .where((n) => n.sectionId == sectionId && !n.isRead)
        .length;
  }

  @override
  Map<String, int> getAllUnreadCounts() {
    final Map<String, int> counts = {};
    for (final notification in _notifications) {
      if (!notification.isRead) {
        counts[notification.sectionId] =
            (counts[notification.sectionId] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _updateUnreadCounts();
    }
  }

  @override
  void markAllAsReadForSection(String sectionId) {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].sectionId == sectionId) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _updateUnreadCounts();
  }

  @override
  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _updateUnreadCounts();
  }

  void _updateUnreadCounts() {
    _unreadCountsNotifier.value = getAllUnreadCounts();
  }

  static List<AppNotification> _getMockNotifications() {
    final now = DateTime.now();
    return [
      // Real Estate Notifications (3 unread)
      AppNotification(
        id: 'notif-re-1',
        sectionId: 'real_estate',
        type: 'price_drop',
        title: 'تخفيض في سعر شقة بطنطا',
        body: 'تم خفض سعر الشقة المعروضة في شارع النادي بنسبة 5%',
        createdAt: now.subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-re-2',
        sectionId: 'real_estate',
        type: 'new_property',
        title: 'فيلا جديدة للبيع بالغربية',
        body: 'تم إضافة فيلا سكنية جديدة بمساحة 350m²',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-re-3',
        sectionId: 'real_estate',
        type: 'offer',
        title: 'عرض مميز على صك أرض',
        body: 'أرض زراعية موثقة بصك إلكتروني بسعر مميز',
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),

      // Building Materials Notifications (5 unread)
      AppNotification(
        id: 'notif-bm-1',
        sectionId: 'building_materials',
        type: 'price_change',
        title: 'تحديث سعر حديد التسليح اليوم',
        body: 'انخفاض سعر طن حديد عز اليوم بمقدار 500 ج.م',
        createdAt: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-bm-2',
        sectionId: 'building_materials',
        type: 'order_status',
        title: 'تم شحن طلبية الأسمنت',
        body: 'شحنة الأسمنت البورتلاندي في الطريق إلى موقع المشروع',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-bm-3',
        sectionId: 'building_materials',
        type: 'offer',
        title: 'عرض الجملة على الطوب الطفلي',
        body: 'خصم 10% عند طلب 10,000 طوبة طفلية',
        createdAt: now.subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-bm-4',
        sectionId: 'building_materials',
        type: 'supplier_update',
        title: 'مورد جديد للمستلزمات الكهربائية',
        body: 'انضمام مورد مصنع السويدي للكابلات بأسعار الجملة',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-bm-5',
        sectionId: 'building_materials',
        type: 'offer',
        title: 'خصم على خلطات العزل المائي',
        body: 'احصل على خصم 15% على مواد السيكا والعزل',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: false,
      ),

      // Home Services Notifications (1 unread)
      AppNotification(
        id: 'notif-hs-1',
        sectionId: 'services',
        type: 'booking_confirm',
        title: 'تأكيد زيارة الفني اليوم',
        body: 'وصل المهندس أحمد لتنفيذ صيانة التكييفات الساعة 4:00 مساءً',
        createdAt: now.subtract(const Duration(minutes: 45)),
        isRead: false,
      ),

      // Home Appliances Notifications (0 unread)
      AppNotification(
        id: 'notif-ha-1',
        sectionId: 'home_appliances',
        type: 'shipping_update',
        title: 'تم تسليم شاشة LG 55 بوصة',
        body: 'تم استلام المنتج بنجاح وتفعيل الضمان لمدة سنتين',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),

      // Cars Notifications (2 unread)
      AppNotification(
        id: 'notif-car-1',
        sectionId: 'cars',
        type: 'test_drive_confirmed',
        title: 'تأكيد حجز تجربة القيادة',
        body: 'تم تأكيد موعد قيادة تويوتا كورولا 2023 اليوم 6:00 م في فرع طنطا شارع البحر',
        createdAt: now.subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-car-2',
        sectionId: 'cars',
        type: 'inspection_ready',
        title: 'تقرير الفحص الفني المعتمد جاهز',
        body: 'صدر تقرير الفحص الفني لسيارة هيونداي توسان بنسبة تقييم 94% فابريكا بالكامل',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-car-3',
        sectionId: 'cars',
        type: 'price_drop',
        title: 'انخفاض سعر سيارة في قائمة مفضلتك',
        body: 'تم تخفيض سعر كيا سبورتاج 2024 بمقدار 35,000 ج.م لدى أوتو ستار',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-car-4',
        sectionId: 'cars',
        type: 'new_arrivals',
        title: 'سيارات جديدة مضافة اليوم في الغربية',
        body: 'تمت إضافة 6 سيارات كسر زيرو وضمان معتمد في طنطا والمحلة',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),

      // Fashion & Clothing Notifications (2 unread)
      AppNotification(
        id: 'notif-fsh-1',
        sectionId: 'fashion',
        type: 'order_delivery',
        title: 'شحنة الأزياء في الطريق إليك',
        body: 'مندوب الشحن في طريقه لتسليم طلبية الملابس #FSH-4921 مع إمكانية المعاينة قبل الدفع',
        createdAt: now.subtract(const Duration(minutes: 20)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-fsh-2',
        sectionId: 'fashion',
        type: 'promo_coupon',
        title: 'كوبون خصم إضافي %20 فعال الآن',
        body: 'استخدم كود FASHION20 عند الدفع واستمتع بشحن مجاني على الطلبات أكثر من 1000 ج.م',
        createdAt: now.subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif-fsh-3',
        sectionId: 'fashion',
        type: 'new_collection',
        title: 'وصل حديثاً: تشكيلة الموسم الجديد',
        body: 'تصفح أحدث تصاميم الملابس الرجالي والحريمي والأطفال بأفضل الأسعار',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif-fsh-4',
        sectionId: 'fashion',
        type: 'order_status',
        title: 'تم تأكيد طلبك #FSH-3810 بنجاح',
        body: 'فستان ميدي بليسيه + حذاء كلاسيك جاري تجهيزهما للتغليف والشحن',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }
}
