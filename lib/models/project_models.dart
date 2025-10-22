// Takip Statüsü modeli
class FollowupStatus {
  final int statusID;
  final String statusName;
  final String statusColor;

  FollowupStatus({
    required this.statusID,
    required this.statusName,
    required this.statusColor,
  });

  factory FollowupStatus.fromJson(Map<String, dynamic> json) {
    return FollowupStatus(
      statusID: (json['statusID'] as num).toInt(),
      statusName: json['statusName'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? '#000000',
    );
  }
}

// Takip Türü modeli
class FollowupType {
  final int typeID;
  final String typeName;

  FollowupType({
    required this.typeID,
    required this.typeName,
  });

  factory FollowupType.fromJson(Map<String, dynamic> json) {
    return FollowupType(
      typeID: (json['typeID'] as num).toInt(),
      typeName: json['typeName'] as String? ?? '',
    );
  }
}

// Döküman modeli
class ProjectDocument {
  final int documentID;
  final int documentTypeID;
  final String documentType;
  final String partner;
  final String validityDate;
  final String documentURL;
  final String createDate;
  final String? documentDesc;
  final bool isCompDocument;

  ProjectDocument({
    required this.documentID,
    required this.documentTypeID,
    required this.documentType,
    required this.partner,
    required this.validityDate,
    required this.documentURL,
    required this.createDate,
    this.documentDesc,
    this.isCompDocument = false,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      documentID: (json['documentID'] as num).toInt(),
      documentTypeID: (json['documentTypeID'] as num?)?.toInt() ?? 0,
      documentType: json['documentType'] as String? ?? '',
      partner: json['partner'] as String? ?? '',
      validityDate: json['validityDate'] as String? ?? '',
      documentURL: json['documentURL'] as String? ?? '',
      createDate: json['createDate'] as String? ?? '',
      documentDesc: json['documentDesc'] as String?,
      isCompDocument: _parseBoolean(json['isCompDocument']),
    );
  }

  static bool _parseBoolean(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

// Gerekli belge modeli
class RequiredDocument {
  final int documentID;
  final String documentName;
  final String statusText;
  final bool isRequired;
  final bool isAdded;

  RequiredDocument({
    required this.documentID,
    required this.documentName,
    required this.statusText,
    required this.isRequired,
    required this.isAdded,
  });

  factory RequiredDocument.fromJson(Map<String, dynamic> json) {
    return RequiredDocument(
      documentID: (json['documentID'] as num).toInt(),
      documentName: json['documentName'] as String? ?? '',
      statusText: json['statusText'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      isAdded: json['isAdded'] as bool? ?? false,
    );
  }
}

// Tracking modeli
class ProjectTracking {
  final int trackID;
  final String trackTitle;
  final String trackDesc;
  final int trackTypeID;
  final String trackTypeName;
  final String typeColor;
  final String typeColorBg;
  final String statusName;
  final String statusColor;
  final String statusBgColor;
  final String trackDueDate;
  final String trackRemindDate;
  final int assignedUserID;
  final String assignedUser;
  final String createdDate;
  final String updatedDate;

  ProjectTracking({
    required this.trackID,
    required this.trackTitle,
    required this.trackDesc,
    required this.trackTypeID,
    required this.trackTypeName,
    required this.typeColor,
    required this.typeColorBg,
    required this.statusName,
    required this.statusColor,
    required this.statusBgColor,
    required this.trackDueDate,
    required this.trackRemindDate,
    required this.assignedUserID,
    required this.assignedUser,
    required this.createdDate,
    required this.updatedDate,
  });

  factory ProjectTracking.fromJson(Map<String, dynamic> json) {
    return ProjectTracking(
      trackID: (json['trackID'] as num).toInt(),
      trackTitle: json['trackTitle'] as String? ?? '',
      trackDesc: json['trackDesc'] as String? ?? '',
      trackTypeID: (json['trackTypeID'] as num?)?.toInt() ?? 0,
      trackTypeName: json['trackTypeName'] as String? ?? '',
      typeColor: json['typeColor'] as String? ?? '#FFFFFF',
      typeColorBg: json['typeColorBg'] as String? ?? '#EF4444',
      statusName: json['statusName'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? '#000000',
      statusBgColor: json['statusBgColor'] as String? ?? '#E5E7EB',
      trackDueDate: json['trackDueDate'] as String? ?? '',
      trackRemindDate: json['trackRemindDate'] as String? ?? '',
      assignedUserID: (json['assignedUserID'] as num?)?.toInt() ?? 0,
      assignedUser: json['assignedUser'] as String? ?? '',
      createdDate: json['createdDate'] as String? ?? '',
      updatedDate: json['updatedDate'] as String? ?? '',
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
  final List<RequiredDocument> requiredDocuments;
  final List<ProjectTracking> trackings;

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
    required this.requiredDocuments,
    required this.trackings,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    final documentsJson = json['documents'] as List<dynamic>? ?? [];
    final documents = documentsJson
        .map((e) => ProjectDocument.fromJson(e as Map<String, dynamic>))
        .toList();

    final requiredDocsJson = json['requiredDocuments'] as List<dynamic>? ?? [];
    final requiredDocuments = requiredDocsJson
        .map((e) => RequiredDocument.fromJson(e as Map<String, dynamic>))
        .toList();

    final trackingsJson = json['trackings'] as List<dynamic>? ?? [];
    final trackings = trackingsJson
        .map((e) => ProjectTracking.fromJson(e as Map<String, dynamic>))
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
      requiredDocuments: requiredDocuments,
      trackings: trackings,
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

// Proje belge ekleme request
class AddProjectDocumentRequest {
  final String userToken;
  final int appID;
  final int compID;
  final int documentType;
  final String documentDesc;
  final String file;

  AddProjectDocumentRequest({
    required this.userToken,
    required this.appID,
    required this.compID,
    required this.documentType,
    required this.documentDesc,
    required this.file,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'appID': appID,
      'compID': compID,
      'documentType': documentType,
      'documentDesc': documentDesc,
      'file': file,
    };
  }
}

// Proje belge güncelleme request
class UpdateProjectDocumentRequest {
  final String userToken;
  final int appID;
  final int compID;
  final int documentID;
  final int documentType;
  final String documentDesc;
  final String file;
  final int isCompDocument;

  UpdateProjectDocumentRequest({
    required this.userToken,
    required this.appID,
    required this.compID,
    required this.documentID,
    required this.documentType,
    required this.documentDesc,
    required this.file,
    this.isCompDocument = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'appID': appID,
      'compID': compID,
      'documentID': documentID,
      'documentType': documentType,
      'documentDesc': documentDesc,
      'file': file,
      'isCompDocument': isCompDocument,
    };
  }
}

// Proje belge silme request
class DeleteProjectDocumentRequest {
  final String userToken;
  final int appID;
  final int documentID;

  DeleteProjectDocumentRequest({
    required this.userToken,
    required this.appID,
    required this.documentID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'appID': appID,
      'documentID': documentID,
    };
  }
}

// Proje belge ekleme response
class AddProjectDocumentResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? documentID;
  final int? statusCode;

  AddProjectDocumentResponse({
    required this.error,
    required this.success,
    this.message,
    this.documentID,
    this.statusCode,
  });

  factory AddProjectDocumentResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddProjectDocumentResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? 
               (json['success_message'] as String?) ?? 
               (json['error_message'] as String?),
      documentID: data != null ? (data['documentID'] as num?)?.toInt() : null,
      statusCode: statusCode,
    );
  }
}

// Takip ekleme request
class AddTrackingRequest {
  final String userToken;
  final int appID;
  final int compID;
  final int typeID;
  final int statusID;
  final String trackTitle;
  final String trackDesc;
  final String trackDueDate;
  final String trackRemindDate;
  final int assignedUserID;
  final int isCompNotification;

  AddTrackingRequest({
    required this.userToken,
    required this.appID,
    required this.compID,
    required this.typeID,
    required this.statusID,
    required this.trackTitle,
    required this.trackDesc,
    required this.trackDueDate,
    required this.trackRemindDate,
    required this.assignedUserID,
    this.isCompNotification = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'appID': appID,
      'compID': compID,
      'typeID': typeID,
      'statusID': statusID,
      'trackTitle': trackTitle,
      'trackDesc': trackDesc,
      'trackDueDate': trackDueDate,
      'trackRemindDate': trackRemindDate,
      'assignedUserID': assignedUserID,
      'isCompNotification': isCompNotification,
    };
  }
}

// Takip ekleme response
class AddTrackingResponse {
  final bool error;
  final bool success;
  final String? message;
  final int? followupID;
  final int? statusCode;

  AddTrackingResponse({
    required this.error,
    required this.success,
    this.message,
    this.followupID,
    this.statusCode,
  });

  factory AddTrackingResponse.fromJson(Map<String, dynamic> json, int? statusCode) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddTrackingResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? 
               (json['success_message'] as String?) ?? 
               (json['error_message'] as String?),
      followupID: data != null ? (data['followupID'] as num?)?.toInt() : null,
      statusCode: statusCode,
    );
  }
}
