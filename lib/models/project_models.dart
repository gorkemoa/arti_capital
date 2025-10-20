// Döküman modeli
class ProjectDocument {
  final int documentID;
  final String documentType;
  final String partner;
  final String validityDate;
  final String documentURL;
  final String createDate;

  ProjectDocument({
    required this.documentID,
    required this.documentType,
    required this.partner,
    required this.validityDate,
    required this.documentURL,
    required this.createDate,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      documentID: (json['documentID'] as num).toInt(),
      documentType: json['documentType'] as String? ?? '',
      partner: json['partner'] as String? ?? '',
      validityDate: json['validityDate'] as String? ?? '',
      documentURL: json['documentURL'] as String? ?? '',
      createDate: json['createDate'] as String? ?? '',
    );
  }
}

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

// Proje güncelleme request
class UpdateProjectRequest {
  final String userToken;
  final int projectID;
  final int compID;
  final int compAdrID;
  final int serviceID;
  final String projectTitle;
  final String projectDesc;

  UpdateProjectRequest({
    required this.userToken,
    required this.projectID,
    required this.compID,
    required this.compAdrID,
    required this.serviceID,
    required this.projectTitle,
    required this.projectDesc,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'projectID': projectID,
      'compID': compID,
      'compAdrID': compAdrID,
      'serviceID': serviceID,
      'projectTitle': projectTitle,
      'projectDesc': projectDesc,
    };
  }
}

// Proje güncelleme response
class UpdateProjectResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? projectID;
  final int? statusCode;

  UpdateProjectResponse({
    required this.error,
    required this.success,
    this.message,
    this.projectID,
    this.statusCode,
  });

  factory UpdateProjectResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    final data = json['data'] as Map<String, dynamic>?;
    return UpdateProjectResponse(
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

// Proje silme request
class DeleteProjectRequest {
  final String userToken;
  final int projectID;

  DeleteProjectRequest({
    required this.userToken,
    required this.projectID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'projectID': projectID,
    };
  }
}

// Proje silme response
class DeleteProjectResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? statusCode;

  DeleteProjectResponse({
    required this.error,
    required this.success,
    this.message,
    this.statusCode,
  });

  factory DeleteProjectResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    return DeleteProjectResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? 
               (json['success_message'] as String?) ?? 
               (json['error_message'] as String?),
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

// Detaylı proje modeli
class ProjectDetail {
  final int appID;
  final String appCode;
  final String appTitle;
  final String? appDesc;
  final String appProgress;
  final int compID;
  final String compName;
  final int compAdrID;
  final String compAdrType;
  final String compAdrCity;
  final String compAdrDistrict;
  final String compAddress;
  final int? serviceID;
  final String? serviceName;
  final int userID;
  final String personName;
  final int appStatus;
  final String statusName;
  final String statusColor;
  final String createDate;
  final List<ProjectDocument> documents;

  ProjectDetail({
    required this.appID,
    required this.appCode,
    required this.appTitle,
    this.appDesc,
    required this.appProgress,
    required this.compID,
    required this.compName,
    required this.compAdrID,
    required this.compAdrType,
    required this.compAdrCity,
    required this.compAdrDistrict,
    required this.compAddress,
    this.serviceID,
    this.serviceName,
    required this.userID,
    required this.personName,
    required this.appStatus,
    required this.statusName,
    required this.statusColor,
    required this.createDate,
    required this.documents,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final documentsJson = json['documents'] as List<dynamic>? ?? [];
    final documents = documentsJson
        .map((e) => ProjectDocument.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProjectDetail(
      appID: (json['appID'] as num).toInt(),
      appCode: json['appCode'] as String? ?? '',
      appTitle: json['appTitle'] as String? ?? '',
      appDesc: json['appDesc'] as String?,
      appProgress: json['appProgress'] as String? ?? '%0',
      compID: (json['compID'] as num).toInt(),
      compName: json['compName'] as String? ?? '',
      compAdrID: (json['compAdrID'] as num).toInt(),
      compAdrType: json['compAdrType'] as String? ?? '',
      compAdrCity: json['compAdrCity'] as String? ?? '',
      compAdrDistrict: json['compAdrDistrict'] as String? ?? '',
      compAddress: json['compAddress'] as String? ?? '',
      serviceID: (json['serviceID'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      userID: (json['userID'] as num).toInt(),
      personName: json['personName'] as String? ?? '',
      appStatus: (json['appStatus'] as num).toInt(),
      statusName: json['statusName'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? '#009ef7',
      createDate: json['createDate'] as String? ?? '',
      documents: documents,
    );
  }
}

class GetProjectDetailResponse {
  final bool error;
  final bool success;
  final ProjectDetail? project;
  final String? errorMessage;
  final int? statusCode;

  GetProjectDetailResponse({
    required this.error,
    required this.success,
    this.project,
    this.errorMessage,
    this.statusCode,
  });

  factory GetProjectDetailResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    final data = json['data'] as Map<String, dynamic>?;
    final projectJson = data?['project'] as Map<String, dynamic>?;
    
    return GetProjectDetailResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      project: projectJson != null ? ProjectDetail.fromJson(projectJson) : null,
      errorMessage: (json['message'] as String?) ?? 
                    (json['error_message'] as String?),
      statusCode: statusCode,
    );
  }
}
