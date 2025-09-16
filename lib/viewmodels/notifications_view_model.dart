import 'package:flutter/foundation.dart';

import '../models/notification_models.dart';
import '../services/notifications_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationsService _notificationsService = NotificationsService();

  bool loading = true;
  String? errorMessage;
  List<NotificationItem> notifications = const [];

  NotificationsViewModel() {
    load();
  }

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    final resp = await _notificationsService.getNotifications();
    if (resp.success) {
      notifications = resp.notifications;
      errorMessage = null;
    } else {
      notifications = const [];
      errorMessage = resp.errorMessage ?? 'Bildirimler alınamadı';
    }

    loading = false;
    notifyListeners();
  }

  Future<String?> markAllRead() async {
    try {
      final res = await NotificationsService().allReadNotifications();
      if (res.success) {
        await load();
      }
      return res.message;
    } catch (e) {
      return 'Bir hata oluştu';
    }
  }

  Future<String?> deleteOne(int notId) async {
    try {
      final res = await _notificationsService.deleteNotification(notID: notId);
      if (res.success) {
        notifications = notifications.where((e) => e.id != notId).toList();
        notifyListeners();
      }
      return res.message;
    } catch (e) {
      return 'Bir hata oluştu';
    }
  }

  Future<String?> deleteAll() async {
    try {
      final res = await _notificationsService.deleteAllNotifications();
      if (res.success) {
        notifications = const [];
        notifyListeners();
      }
      return res.message;
    } catch (e) {
      return 'Bir hata oluştu';
    }
  }
}


