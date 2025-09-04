import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/user_request_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class UserService {
  Future<GetUserResponse> getUser() async {
    try {
      final token = StorageService.getToken();
      final userId = StorageService.getUserId();
      
      if (token == null) {
        return GetUserResponse(
          error: true,
          success: false,
          errorMessage: 'Token bulunamadı',
        );
      }
      
      if (userId == null) {
        return GetUserResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı ID bulunamadı',
        );
      }

      // Platform bilgisini al
      String platform = 'unknown';
      if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      }

      // Versiyon bilgisini al
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      final request = GetUserRequest(
        userToken: token,
        version: version,
        platform: platform,
      );

      // Endpoint'e userId'yi ekle
      final endpoint = '${AppConstants.getUser}/$userId';
      
      AppLogger.i('PUT $endpoint', tag: 'GET_USER');
      AppLogger.i(request.toJson().toString(), tag: 'GET_USER_REQ');
      
      final resp = await ApiClient.putJson(
        endpoint,
        data: request.toJson(),
      );
      
      // Response data'sını güvenli bir şekilde kontrol et
      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      
      if (responseData is String) {
        // Eğer response String ise, JSON parse et
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_USER');
          return GetUserResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_USER');
        return GetUserResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }
      
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_USER');
      AppLogger.i(body.toString(), tag: 'GET_USER_RES');
      
      final getUserResponse = GetUserResponse.fromJson(body, resp.statusCode);
      
      // Kullanıcı bilgileri başarılı ise kaydet
      if (getUserResponse.success && getUserResponse.user != null) {
        await StorageService.saveUserData(getUserResponse.user!.toJson().toString());
      }
      
      return getUserResponse;
    } on ApiException catch (e) {
      AppLogger.e('Get user error ${e.statusCode} ${e.message}', tag: 'GET_USER');
      return GetUserResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in getUser: $e', tag: 'GET_USER');
      return GetUserResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<UpdateUserResponse> updateUser(UpdateUserRequest request) async {
    try {
      AppLogger.i('PUT ${AppConstants.updateUser}', tag: 'UPDATE_USER');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_USER_REQ');

      final resp = await ApiClient.putJson(
        AppConstants.updateUser,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_USER');
          return UpdateUserResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_USER');
        return UpdateUserResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_USER');
      AppLogger.i(body.toString(), tag: 'UPDATE_USER_RES');

      final updateResp = UpdateUserResponse.fromJson(body, resp.statusCode);

      return updateResp;
    } on ApiException catch (e) {
      AppLogger.e('Update user error ${e.statusCode} ${e.message}', tag: 'UPDATE_USER');
      return UpdateUserResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateUser: $e', tag: 'UPDATE_USER');
      return UpdateUserResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }
}
