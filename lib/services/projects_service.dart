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
}