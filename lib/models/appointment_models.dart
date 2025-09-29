class AppointmentItem {
  final int appointmentID;
  final int userID;
  final int compID;
  final String compName;
  final String appointmentTitle;
  final String appointmentDesc;
  final String appointmentDate; // Sunucu dd.MM.yyyy HH:mm string döndürüyor
  final int appointmentStatus;
  final int statusID;
  final String statusName;
  final String statusColor;
  final String createDate;

  AppointmentItem({
    required this.appointmentID,
    required this.userID,
    required this.compID,
    required this.compName,
    required this.appointmentTitle,
    required this.appointmentDesc,
    required this.appointmentDate,
    required this.appointmentStatus,
    required this.statusID,
    required this.statusName,
    required this.statusColor,
    required this.createDate,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AppointmentItem(
      appointmentID: parseInt(json['appointmentID']),
      userID: parseInt(json['userID']),
      compID: parseInt(json['compID']),
      compName: (json['compName'] ?? '').toString(),
      appointmentTitle: (json['appointmentTitle'] ?? '').toString(),
      appointmentDesc: (json['appointmentDesc'] ?? '').toString(),
      appointmentDate: (json['appointmentDate'] ?? '').toString(),
      appointmentStatus: parseInt(json['appointmentStatus']),
      statusID: parseInt(json['statusID']),
      statusName: (json['statusName'] ?? '').toString(),
      statusColor: (json['statusColor'] ?? '').toString(),
      createDate: (json['createDate'] ?? '').toString(),
    );
  }
}

class GetAppointmentsResponse {
  final bool error;
  final bool success;
  final String message;
  final List<AppointmentItem> appointments;
  final int totalCount;
  final int? statusCode;
  final String? errorMessage;

  GetAppointmentsResponse({
    required this.error,
    required this.success,
    required this.message,
    required this.appointments,
    required this.totalCount,
    this.statusCode,
    this.errorMessage,
  });

  factory GetAppointmentsResponse.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['appointments'] : null) as List<dynamic>?;
    return GetAppointmentsResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      message: (json['message'] ?? '').toString(),
      appointments: (list ?? const <dynamic>[]) 
          .whereType<Map<String, dynamic>>()
          .map((e) => AppointmentItem.fromJson(e))
          .toList(),
      totalCount: (data?['totalCount'] ?? 0) is String
          ? int.tryParse((data?['totalCount']).toString()) ?? 0
          : (data?['totalCount'] ?? 0) as int,
      statusCode: statusCode,
      errorMessage: null,
    );
  }
}


