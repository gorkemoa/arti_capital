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
}


