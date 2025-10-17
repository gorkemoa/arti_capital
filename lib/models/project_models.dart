
class ProjectItem {
  final int appID;
  final String appCode;
  final String appTitle;
  final String? appDesc;
  final String appProgress;
  final int compID;
  final String compName;
  final int? serviceID;
  final String? serviceName;
  final int userID;
  final String personName;
  final int appStatus;
  final String statusName;
  final String statusColor;
  final String createDate;

  ProjectItem({
    required this.appID,
    required this.appCode,
    required this.appTitle,
    this.appDesc,
    required this.appProgress,
    required this.compID,
    required this.compName,
    this.serviceID,
    this.serviceName,
    required this.userID,
    required this.personName,
    required this.appStatus,
    required this.statusName,
    required this.statusColor,
    required this.createDate,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      appID: (json['appID'] as num).toInt(),
      appCode: json['appCode'] as String? ?? '',
      appTitle: json['appTitle'] as String? ?? '',
      appDesc: json['appDesc'] as String?,
      appProgress: json['appProgress'] as String? ?? '%0',
      compID: (json['compID'] as num).toInt(),
      compName: json['compName'] as String? ?? '',
      serviceID: (json['serviceID'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      userID: (json['userID'] as num).toInt(),
      personName: json['personName'] as String? ?? '',
      appStatus: (json['appStatus'] as num).toInt(),
      statusName: json['statusName'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? '#009ef7',
      createDate: json['createDate'] as String? ?? '',
    );
  }
}

class AddProjectRequest {
  final String userToken;
  final int compID;
  final int compAdrID;
  final int serviceID;
  final String projectTitle;
  final String projectDesc;

  AddProjectRequest({
    required this.userToken,
    required this.compID,
    required this.compAdrID,
    required this.serviceID,
    required this.projectTitle,
    required this.projectDesc,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'compAdrID': compAdrID,
      'serviceID': serviceID,
      'projectTitle': projectTitle,
      'projectDesc': projectDesc,
    };
  }
}

class AddProjectResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? projectID;
  final int? statusCode;

  AddProjectResponse({
    required this.error,
    required this.success,
    this.message,
    this.projectID,
    this.statusCode,
  });

  factory AddProjectResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddProjectResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? 
               (json['success_message'] as String?) ?? 
               (json['error_message'] as String?),
      projectID: data != null ? (data['projectID'] as num?)?.toInt() : null,
      statusCode: statusCode,
    );
  }
}

class BaseSimpleResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? statusCode;

  BaseSimpleResponse({
    required this.error,
    required this.success,
    this.message,
    this.statusCode,
  });

  factory BaseSimpleResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    return BaseSimpleResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? 
               (json['success_message'] as String?) ?? 
               (json['error_message'] as String?),
      statusCode: statusCode,
    );
  }
}
