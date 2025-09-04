class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final int typeId;
  final String url;
  final String image;
  final bool isRead;
  final String createDate;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.typeId,
    required this.url,
    required this.image,
    required this.isRead,
    required this.createDate,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? '',
        typeId: json['type_id'] as int? ?? 0,
        url: json['url'] as String? ?? '',
        image: json['image'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createDate: json['create_date'] as String? ?? '',
      );
}

class GetNotificationsResponse {
  final bool error;
  final bool success;
  final List<NotificationItem> notifications;
  final String? errorMessage;
  final int? statusCode;

  GetNotificationsResponse({
    required this.error,
    required this.success,
    required this.notifications,
    this.errorMessage,
    this.statusCode,
  });

  factory GetNotificationsResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['notifications'] as List? : null) ?? [];
    return GetNotificationsResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      notifications: list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


