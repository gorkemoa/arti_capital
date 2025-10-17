
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
