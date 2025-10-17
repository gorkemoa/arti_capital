import 'dart:convert';
import '../models/project_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class ProjectsService {

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