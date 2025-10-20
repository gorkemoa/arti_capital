import 'dart:convert';
import '../models/project_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class ProjectsService {

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
}