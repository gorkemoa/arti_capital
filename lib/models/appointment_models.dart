class AppointmentLog {
  final int logID;
  final String logTitle;
  final String logDesc;
  final String logUser;
  final String logDate;

  AppointmentLog({
    required this.logID,
    required this.logTitle,
    required this.logDesc,
    required this.logUser,
    required this.logDate,
  });

  factory AppointmentLog.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AppointmentLog(
      logID: parseInt(json['logID']),
      logTitle: (json['logTitle'] ?? '').toString(),
      logDesc: (json['logDesc'] ?? '').toString(),
      logUser: (json['logUser'] ?? '').toString(),
      logDate: (json['logDate'] ?? '').toString(),
    );
  }
}

class AppointmentItem {
  final int appointmentID;
  final int userID;
  final int compID;
  final String compName;
  final String appointmentTitle;
  final String appointmentDesc;
  final String appointmentLocation;
  final String appointmentDate; // Sunucu dd.MM.yyyy HH:mm string döndürüyor
  final int appointmentPriority;
  final int appointmentStatus;
  final int statusID;
  final String statusName;
  final String statusColor;
  final String priorityName;
  final String priorityColor;
  final String createDate;
  final List<AppointmentLog> logs;

  AppointmentItem({
    required this.appointmentID,
    required this.userID,
    required this.compID,
    required this.compName,
    required this.appointmentTitle,
    required this.appointmentDesc,
    required this.appointmentLocation,
    required this.appointmentDate,
    required this.appointmentPriority,
    required this.appointmentStatus,
    required this.statusID,
    required this.statusName,
    required this.statusColor,
    required this.priorityName,
    required this.priorityColor,
    required this.createDate,
    required this.logs,
  });

  factory AppointmentItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final logsList = (json['logs'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map((e) => AppointmentLog.fromJson(e))
        .toList() ?? <AppointmentLog>[];

    return AppointmentItem(
      appointmentID: parseInt(json['appointmentID']),
      userID: parseInt(json['userID']),
      compID: parseInt(json['compID']),
      compName: (json['compName'] ?? '').toString(),
      appointmentTitle: (json['appointmentTitle'] ?? '').toString(),
      appointmentDesc: (json['appointmentDesc'] ?? '').toString(),
      appointmentLocation: (json['appointmentLocation'] ?? '').toString(),
      appointmentDate: (json['appointmentDate'] ?? '').toString(),
      appointmentPriority: parseInt(json['appointmentPriority']),
      appointmentStatus: parseInt(json['appointmentStatus']),
      statusID: parseInt(json['statusID']),
      statusName: (json['statusName'] ?? '').toString(),
      statusColor: (json['statusColor'] ?? '').toString(),
      priorityName: (json['priorityName'] ?? '').toString(),
      priorityColor: (json['priorityColor'] ?? '').toString(),
      createDate: (json['createDate'] ?? '').toString(),
      logs: logsList,
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




class AddAppointmentResponse {
  final bool error;
  final bool success;
  final String message;
  final int? appointmentID;
  final int? statusCode;
  final String? errorMessage;

  AddAppointmentResponse({
    required this.error,
    required this.success,
    required this.message,
    this.appointmentID,
    this.statusCode,
    this.errorMessage,
  });

  factory AddAppointmentResponse.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    final data = json['data'] as Map<String, dynamic>?;
    int? id;
    if (data != null) {
      final v = data['appointmentID'];
      if (v is int) id = v; else if (v is String) id = int.tryParse(v);
    }
    return AddAppointmentResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      message: (json['message'] ?? '').toString(),
      appointmentID: id,
      statusCode: statusCode,
      errorMessage: null,
    );
  }
}

class DeleteAppointmentResponse {
  final bool error;
  final bool success;
  final String message;
  final int? statusCode;
  final String? errorMessage;

  DeleteAppointmentResponse({
    required this.error,
    required this.success,
    required this.message,
    this.statusCode,
    this.errorMessage,
  });

  factory DeleteAppointmentResponse.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    return DeleteAppointmentResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      message: (json['message'] ?? '').toString(),
      statusCode: statusCode,
      errorMessage: json['error_message']?.toString(),
    );
  }
}

class AppointmentStatus {
  final int statusID;
  final String statusName;
  final String statusColor;

  AppointmentStatus({
    required this.statusID,
    required this.statusName,
    required this.statusColor,
  });

  factory AppointmentStatus.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AppointmentStatus(
      statusID: parseInt(json['statusID']),
      statusName: (json['statusName'] ?? '').toString(),
      statusColor: (json['statusColor'] ?? '').toString(),
    );
  }
}

class GetAppointmentStatusesResponse {
  final bool error;
  final bool success;
  final List<AppointmentStatus> statuses;
  final String message;
  final int? statusCode;
  final String? errorMessage;

  GetAppointmentStatusesResponse({
    required this.error,
    required this.success,
    required this.statuses,
    required this.message,
    this.statusCode,
    this.errorMessage,
  });

  factory GetAppointmentStatusesResponse.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    final List<AppointmentStatus> statusList = [];
    if (json['data'] != null && json['data']['statuses'] != null) {
      final statusesData = json['data']['statuses'] as List<dynamic>;
      for (final item in statusesData) {
        if (item is Map<String, dynamic>) {
          statusList.add(AppointmentStatus.fromJson(item));
        }
      }
    }

    return GetAppointmentStatusesResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      statuses: statusList,
      message: (json['message'] ?? '').toString(),
      statusCode: statusCode,
      errorMessage: json['error_message']?.toString(),
    );
  }
}

class AppointmentPriority {
  final int priorityID;
  final String priorityName;
  final String priorityColor;

  AppointmentPriority({
    required this.priorityID,
    required this.priorityName,
    required this.priorityColor,
  });

  factory AppointmentPriority.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AppointmentPriority(
      priorityID: parseInt(json['priorityID']),
      priorityName: (json['priorityName'] ?? '').toString(),
      priorityColor: (json['priorityColor'] ?? '').toString(),
    );
  }
}

class GetAppointmentPrioritiesResponse {
  final bool error;
  final bool success;
  final List<AppointmentPriority> priorities;
  final String message;
  final int? statusCode;
  final String? errorMessage;

  GetAppointmentPrioritiesResponse({
    required this.error,
    required this.success,
    required this.priorities,
    required this.message,
    this.statusCode,
    this.errorMessage,
  });

  factory GetAppointmentPrioritiesResponse.fromJson(Map<String, dynamic> json, [int? statusCode]) {
    final List<AppointmentPriority> priorityList = [];
    if (json['data'] != null && json['data']['priorities'] != null) {
      final prioritiesData = json['data']['priorities'] as List<dynamic>;
      for (final item in prioritiesData) {
        if (item is Map<String, dynamic>) {
          priorityList.add(AppointmentPriority.fromJson(item));
        }
      }
    }

    return GetAppointmentPrioritiesResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      priorities: priorityList,
      message: (json['message'] ?? '').toString(),
      statusCode: statusCode,
      errorMessage: json['error_message']?.toString(),
    );
  }
}
