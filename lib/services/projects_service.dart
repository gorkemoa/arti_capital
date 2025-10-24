import 'dart:convert';
import '../models/project_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class ProjectsService {

  // Takip Statüslerini getir
  Future<List<FollowupStatus>> getFollowupStatuses() async {
    try {
      final endpoint = AppConstants.getFollowupStatuses;
      AppLogger.i('GET $endpoint', tag: 'GET_FOLLOWUP_STATUSES');

      final resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_FOLLOWUP_STATUSES');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_FOLLOWUP_STATUSES');
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_FOLLOWUP_STATUSES');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final statusesJson = (data['statuses'] as List<dynamic>?) ?? [];
      return statusesJson
          .map((e) => FollowupStatus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get followup statuses error ${e.statusCode} ${e.message}', tag: 'GET_FOLLOWUP_STATUSES');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getFollowupStatuses: $e', tag: 'GET_FOLLOWUP_STATUSES');
      return [];
    }
  }

  // Takip Türlerini getir
  Future<List<FollowupType>> getFollowupTypes() async {
    try {
      final endpoint = AppConstants.getFollowupTypes;
      AppLogger.i('GET $endpoint', tag: 'GET_FOLLOWUP_TYPES');

      final resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_FOLLOWUP_TYPES');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_FOLLOWUP_TYPES');
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_FOLLOWUP_TYPES');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final typesJson = (data['types'] as List<dynamic>?) ?? [];
      return typesJson
          .map((e) => FollowupType.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get followup types error ${e.statusCode} ${e.message}', tag: 'GET_FOLLOWUP_TYPES');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getFollowupTypes: $e', tag: 'GET_FOLLOWUP_TYPES');
      return [];
    }
  }

  // Kişileri getir (Persons/Users)
  Future<List<Map<String, dynamic>>> getPersons() async {
    try {
      final endpoint = AppConstants.getPersons;
      AppLogger.i('GET $endpoint', tag: 'GET_PERSONS');

      final resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_PERSONS');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_PERSONS');
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_PERSONS');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final personsJson = (data['persons'] as List<dynamic>?) ?? [];
      return personsJson
          .map((e) {
            final person = e as Map<String, dynamic>;
            return {
              'id': person['userID'] as int? ?? 0,
              'name': person['userName'] as String? ?? 'Unknown',
              'type': person['userType'] as String? ?? '',
            };
          })
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get persons error ${e.statusCode} ${e.message}', tag: 'GET_PERSONS');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getPersons: $e', tag: 'GET_PERSONS');
      return [];
    }
  }

  // Projeleri getir
  Future<List<ProjectItem>> getProjects({String? searchText}) async {
    try {
      final endpoint = AppConstants.getProjects;
      final query = <String, dynamic>{};
      
      // UserToken'ı StorageService'ten al
      final userToken = StorageService.getToken();
      if (userToken != null && userToken.isNotEmpty) {
        query['userToken'] = userToken;
      }
      
      if (searchText != null && searchText.isNotEmpty) {
        query['searchText'] = searchText;
      }

      AppLogger.i('GET $endpoint?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}', tag: 'GET_PROJECTS');

      final resp = await ApiClient.getJson(endpoint, query: query);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_PROJECTS');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_PROJECTS');
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_PROJECTS');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final projectsJson = (data['projects'] as List<dynamic>?) ?? [];
      return projectsJson
          .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get projects error ${e.statusCode} ${e.message}', tag: 'GET_PROJECTS');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getProjects: $e', tag: 'GET_PROJECTS');
      return [];
    }
  }

  // Proje detayını getir
  Future<GetProjectDetailResponse> getProjectDetail(int projectId) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetProjectDetailResponse(
          error: true,
          success: false,
          errorMessage: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.getProjectDetail(projectId);
      AppLogger.i('GET $endpoint', tag: 'GET_PROJECT_DETAIL');

      final resp = await ApiClient.getJson(endpoint, query: {
        'userToken': token,
      });

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_PROJECT_DETAIL');
          return GetProjectDetailResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_PROJECT_DETAIL');
        return GetProjectDetailResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_PROJECT_DETAIL');
      AppLogger.i(body.toString(), tag: 'GET_PROJECT_DETAIL_RES');

      return GetProjectDetailResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get project detail error ${e.statusCode} ${e.message}', tag: 'GET_PROJECT_DETAIL');
      return GetProjectDetailResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in getProjectDetail: $e', tag: 'GET_PROJECT_DETAIL');
      return GetProjectDetailResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Belgeyi sil
  Future<AddProjectDocumentResponse> deleteProjectDocument({
    required int appID,
    required int documentID,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.deleteProjectDocument;
      AppLogger.i('POST $endpoint', tag: 'DELETE_PROJECT_DOCUMENT');

      final request = DeleteProjectDocumentRequest(
        userToken: token,
        appID: appID,
        documentID: documentID,
      );

      AppLogger.i('Request: appID=$appID, documentID=$documentID', tag: 'DELETE_PROJECT_DOCUMENT');

      final resp = await ApiClient.deleteJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DELETE_PROJECT_DOCUMENT');
          return AddProjectDocumentResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DELETE_PROJECT_DOCUMENT');
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_PROJECT_DOCUMENT');
      AppLogger.i(body.toString(), tag: 'DELETE_PROJECT_DOCUMENT_RES');

      return AddProjectDocumentResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Delete project document error ${e.statusCode} ${e.message}', tag: 'DELETE_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in deleteProjectDocument: $e', tag: 'DELETE_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Yeni proje ekle
  Future<AddProjectResponse> addProject({
    required int compID,
    required int compAdrID,
    required int serviceID,
    required String projectTitle,
    required String projectDesc,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddProjectResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.addProject;
      AppLogger.i('POST $endpoint', tag: 'ADD_PROJECT');

      final request = AddProjectRequest(
        userToken: token,
        compID: compID,
        compAdrID: compAdrID,
        serviceID: serviceID,
        projectTitle: projectTitle,
        projectDesc: projectDesc,
      );

      AppLogger.i('Request: ${request.toJson()}', tag: 'ADD_PROJECT');

      final resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_PROJECT');
          return AddProjectResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_PROJECT');
        return AddProjectResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_PROJECT');
      AppLogger.i(body.toString(), tag: 'ADD_PROJECT_RES');

      return AddProjectResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add project error ${e.statusCode} ${e.message}', tag: 'ADD_PROJECT');
      return AddProjectResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addProject: $e', tag: 'ADD_PROJECT');
      return AddProjectResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Proje güncelle
  Future<UpdateProjectResponse> updateProject({
    required int projectID,
    required int compID,
    required int compAdrID,
    required int serviceID,
    required String projectTitle,
    required String projectDesc,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return UpdateProjectResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.updateProject;
      AppLogger.i('POST $endpoint', tag: 'UPDATE_PROJECT');

      final request = UpdateProjectRequest(
        userToken: token,
        projectID: projectID,
        compID: compID,
        compAdrID: compAdrID,
        serviceID: serviceID,
        projectTitle: projectTitle,
        projectDesc: projectDesc,
      );

      AppLogger.i('Request: ${request.toJson()}', tag: 'UPDATE_PROJECT');

      final resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_PROJECT');
          return UpdateProjectResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_PROJECT');
        return UpdateProjectResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_PROJECT');
      AppLogger.i(body.toString(), tag: 'UPDATE_PROJECT_RES');

      return UpdateProjectResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Update project error ${e.statusCode} ${e.message}', tag: 'UPDATE_PROJECT');
      return UpdateProjectResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateProject: $e', tag: 'UPDATE_PROJECT');
      return UpdateProjectResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Proje sil
  Future<DeleteProjectResponse> deleteProject(int projectID) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return DeleteProjectResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.deleteProject;
      AppLogger.i('POST $endpoint', tag: 'DELETE_PROJECT');

      final request = DeleteProjectRequest(
        userToken: token,
        projectID: projectID,
      );

      AppLogger.i('Request: ${request.toJson()}', tag: 'DELETE_PROJECT');

      final resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DELETE_PROJECT');
          return DeleteProjectResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DELETE_PROJECT');
        return DeleteProjectResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_PROJECT');
      AppLogger.i(body.toString(), tag: 'DELETE_PROJECT_RES');

      return DeleteProjectResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Delete project error ${e.statusCode} ${e.message}', tag: 'DELETE_PROJECT');
      return DeleteProjectResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in deleteProject: $e', tag: 'DELETE_PROJECT');
      return DeleteProjectResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Proje belge ekleme
  Future<AddProjectDocumentResponse> addProjectDocument({
    required int appID,
    required int compID,
    required int documentType,
    required String file,
    String documentDesc = '',
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.addProjectDocument;
      AppLogger.i('POST $endpoint', tag: 'ADD_PROJECT_DOCUMENT');

      final request = AddProjectDocumentRequest(
        userToken: token,
        appID: appID,
        compID: compID,
        documentType: documentType,
        documentDesc: documentDesc,
        file: file,
      );

      AppLogger.i('Request: appID=$appID, compID=$compID, documentType=$documentType', tag: 'ADD_PROJECT_DOCUMENT');

      final resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_PROJECT_DOCUMENT');
          return AddProjectDocumentResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_PROJECT_DOCUMENT');
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_PROJECT_DOCUMENT');
      AppLogger.i(body.toString(), tag: 'ADD_PROJECT_DOCUMENT_RES');

      return AddProjectDocumentResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add project document error ${e.statusCode} ${e.message}', tag: 'ADD_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addProjectDocument: $e', tag: 'ADD_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Belgeyi güncelle
  Future<AddProjectDocumentResponse> updateProjectDocument({
    required int appID,
    required int compID,
    required int documentID,
    required int documentType,
    required String file,
    String documentDesc = '',
    int isCompDocument = 0,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.updateProjectDocument;
      AppLogger.i('POST $endpoint', tag: 'UPDATE_PROJECT_DOCUMENT');

      final request = UpdateProjectDocumentRequest(
        userToken: token,
        appID: appID,
        compID: compID,
        documentID: documentID,
        documentType: documentType,
        documentDesc: documentDesc,
        file: file,
        isCompDocument: isCompDocument,
      );

      AppLogger.i('Request: appID=$appID, compID=$compID, documentID=$documentID, documentType=$documentType', tag: 'UPDATE_PROJECT_DOCUMENT');

      final resp = await ApiClient.putJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_PROJECT_DOCUMENT');
          return AddProjectDocumentResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_PROJECT_DOCUMENT');
        return AddProjectDocumentResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_PROJECT_DOCUMENT');
      AppLogger.i(body.toString(), tag: 'UPDATE_PROJECT_DOCUMENT_RES');

      return AddProjectDocumentResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Update project document error ${e.statusCode} ${e.message}', tag: 'UPDATE_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.i('Unexpected error in updateProjectDocument: $e', tag: 'UPDATE_PROJECT_DOCUMENT');
      return AddProjectDocumentResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Takip ekleme
  Future<AddTrackingResponse> addTracking({
    required int appID,
    required int compID,
    required int typeID,
    required int statusID,
    required String trackTitle,
    required String trackDesc,
    required String trackDueDate,
    required String trackRemindDate,
    required int assignedUserID,
    String? notificationType,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddTrackingResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.addTracking;
      AppLogger.i('POST $endpoint', tag: 'ADD_TRACKING');

      final request = AddTrackingRequest(
        userToken: token,
        appID: appID,
        compID: compID,
        typeID: typeID,
        statusID: statusID,
        trackTitle: trackTitle,
        trackDesc: trackDesc,
        trackDueDate: trackDueDate,
        trackRemindDate: trackRemindDate,
        assignedUserID: assignedUserID,
        notificationType: notificationType,
      );

      AppLogger.i('Request: appID=$appID, compID=$compID, typeID=$typeID, statusID=$statusID', tag: 'ADD_TRACKING');

      final resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_TRACKING');
          return AddTrackingResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_TRACKING');
        return AddTrackingResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_TRACKING');
      AppLogger.i(body.toString(), tag: 'ADD_TRACKING_RES');

      return AddTrackingResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add tracking error ${e.statusCode} ${e.message}', tag: 'ADD_TRACKING');
      return AddTrackingResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addTracking: $e', tag: 'ADD_TRACKING');
      return AddTrackingResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<AddTrackingResponse> updateTracking({
    required int trackID,
    required int appID,
    required int compID,
    required int typeID,
    required int statusID,
    required String trackTitle,
    required String trackDesc,
    required String trackDueDate,
    required String trackRemindDate,
    required int assignedUserID,
    String? notificationType,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddTrackingResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.updateTracking;
      AppLogger.i('PUT $endpoint', tag: 'UPDATE_TRACKING');

      final request = UpdateTrackingRequest(
        userToken: token,
        trackID: trackID,
        appID: appID,
        compID: compID,
        typeID: typeID,
        statusID: statusID,
        trackTitle: trackTitle,
        trackDesc: trackDesc,
        trackDueDate: trackDueDate,
        trackRemindDate: trackRemindDate,
        assignedUserID: assignedUserID,
        notificationType: notificationType,
      );

      AppLogger.i('Request: trackID=$trackID, appID=$appID, compID=$compID, typeID=$typeID, statusID=$statusID', tag: 'UPDATE_TRACKING');

      final resp = await ApiClient.putJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_TRACKING');
          return AddTrackingResponse(
            error: true,
            success: false,
            message: 'Sunucudan gelen yanıt işlenemedi',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_TRACKING');
        return AddTrackingResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_TRACKING');
      AppLogger.i(body.toString(), tag: 'UPDATE_TRACKING_RES');

      return AddTrackingResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Update tracking error ${e.statusCode} ${e.message}', tag: 'UPDATE_TRACKING');
      return AddTrackingResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateTracking: $e', tag: 'UPDATE_TRACKING');
      return AddTrackingResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Takip Sil
  Future<BaseSimpleResponse> deleteTracking({
    required int appID,
    required int trackID,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null || token.isEmpty) {
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Kullanıcı oturumu açılmamış',
        );
      }

      final endpoint = AppConstants.deleteTracking;
      final request = {
        'userToken': token,
        'appID': appID,
        'trackID': trackID,
      };

      AppLogger.i('Delete $endpoint', tag: 'DELETE_TRACKING');

      final resp = await ApiClient.deleteJson(endpoint, data: request);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DELETE_TRACKING');
          return BaseSimpleResponse(
            error: true,
            success: false,
            message: 'Sunucudan gelen yanıt işlenemedi',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DELETE_TRACKING');
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt türü',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_TRACKING');

      return BaseSimpleResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Delete tracking error ${e.statusCode} ${e.message}', tag: 'DELETE_TRACKING');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in deleteTracking: $e', tag: 'DELETE_TRACKING');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Proje bilgisi ekle
  Future<BaseSimpleResponse> addProjectInformation({
    required int appID,
    required int infoID,
    required String infoValue,
    String infoDesc = '',
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.addProjectInformation;
      AppLogger.i('POST $endpoint', tag: 'ADD_INFORMATION');

      final request = {
        'userToken': token,
        'appID': appID,
        'infoID': infoID,
        'infoValue': infoValue,
        'infoDesc': infoDesc,
      };

      AppLogger.i('Request: appID=$appID, infoID=$infoID, infoValue=$infoValue', tag: 'ADD_INFORMATION');

      final resp = await ApiClient.postJson(endpoint, data: request);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_INFORMATION');
          return BaseSimpleResponse(
            error: true,
            success: false,
            message: 'Sunucudan gelen yanıt işlenemedi',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_INFORMATION');
        return BaseSimpleResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt türü',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_INFORMATION');

      return BaseSimpleResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add information error ${e.statusCode} ${e.message}', tag: 'ADD_INFORMATION');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addProjectInformation: $e', tag: 'ADD_INFORMATION');
      return BaseSimpleResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }
}