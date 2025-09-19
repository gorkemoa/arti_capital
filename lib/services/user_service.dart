import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/user_request_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';
import 'app_group_service.dart';
import '../models/company_models.dart';

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
        
        // App Group'a kullanıcı bilgilerini kaydet
        await AppGroupService.setLoggedInUserName(getUserResponse.user!.userFullname);
        await AppGroupService.setUserRank(getUserResponse.user!.userRank);
        
        // Başarılı girişten hemen sonra firmaları da çekip App Group'a yaz
        try {
          final companiesResp = await getCompanies();
          if (companiesResp.success && companiesResp.companies.isNotEmpty) {
            final names = companiesResp.companies
                .map((e) => e.compName)
                .where((e) => e.trim().isNotEmpty)
                .toList();
            if (names.isNotEmpty) {
              await AppGroupService.setCompanies(names);
            }
          }
        } catch (_) {}
        

        // 2FA durumunu ve gönderim tipini backend'den senkronize et
        final user = getUserResponse.user!;
        final isTwoFactorOn = user.isAuth == true;
        await StorageService.saveTwoFactorEnabled(isTwoFactorOn);
        // authTypeID: "1"=SMS, "2"=E-Posta varsayımı
        final typeId = (user.authTypeID != null) ? int.tryParse(user.authTypeID!) : null;
        if (typeId != null && (typeId == 1 || typeId == 2)) {
          await StorageService.saveTwoFactorSendType(typeId);
        }
      }
      
      return getUserResponse;
    } on ApiException catch (e) {
      AppLogger.e('Get user error ${e.statusCode} ${e.message}', tag: 'GET_USER');
      // Yedek güvenlik: 401/403 geldiğinde oturumu temizleyip login'e yönlendir
      if (e.statusCode == 401 || e.statusCode == 403) {
        await StorageService.clearUserData();
        final nav = ApiClient.navigatorKey.currentState;
        if (nav != null) {
          try {
            nav.pushNamedAndRemoveUntil('/login', (route) => false);
          } catch (_) {}
        }
      }
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
      final userId = StorageService.getUserId();
      if (userId == null) {
        return UpdateUserResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı ID bulunamadı',
        );
      }

      final endpoint = AppConstants.updateUserFor(userId);

      AppLogger.i('PUT $endpoint', tag: 'UPDATE_USER');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_USER_REQ');

      final resp = await ApiClient.putJson(
        endpoint,
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

  Future<UpdatePasswordResponse> updatePassword(UpdatePasswordRequest request) async {
    try {
      final endpoint = AppConstants.updatePassword;

      AppLogger.i('PUT $endpoint', tag: 'UPDATE_PASSWORD');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_PASSWORD_REQ');

      final resp = await ApiClient.putJson(
        endpoint,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_PASSWORD');
          return UpdatePasswordResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_PASSWORD');
        return UpdatePasswordResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_PASSWORD');
      AppLogger.i(body.toString(), tag: 'UPDATE_PASSWORD_RES');

      final updateResp = UpdatePasswordResponse.fromJson(body, resp.statusCode);
      return updateResp;
    } on ApiException catch (e) {
      AppLogger.e('Update password error ${e.statusCode} ${e.message}', tag: 'UPDATE_PASSWORD');
      return UpdatePasswordResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updatePassword: $e', tag: 'UPDATE_PASSWORD');
      return UpdatePasswordResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<UpdateAuthResponse> updateAuth(UpdateAuthRequest request) async {
    try {
      final userId = StorageService.getUserId();
      if (userId == null) {
        return UpdateAuthResponse(
          error: true,
          success: false,
          errorMessage: 'Kullanıcı ID bulunamadı',
        );
      }

      final endpoint = AppConstants.updateAuthFor(userId);

      AppLogger.i('PUT $endpoint', tag: 'UPDATE_AUTH');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_AUTH_REQ');

      final resp = await ApiClient.putJson(
        endpoint,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_AUTH');
          return UpdateAuthResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_AUTH');
        return UpdateAuthResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_AUTH');
      AppLogger.i(body.toString(), tag: 'UPDATE_AUTH_RES');

      final updateResp = UpdateAuthResponse.fromJson(body, resp.statusCode);
      return updateResp;
    } on ApiException catch (e) {
      AppLogger.e('Update auth error ${e.statusCode} ${e.message}', tag: 'UPDATE_AUTH');
      return UpdateAuthResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateAuth: $e', tag: 'UPDATE_AUTH');
      return UpdateAuthResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<DeleteUserResponse> deleteUser(DeleteUserRequest request) async {
    try {
      final endpoint = AppConstants.deleteUser;

      AppLogger.i('PUT $endpoint', tag: 'DELETE_USER');
      AppLogger.i(request.toJson().toString(), tag: 'DELETE_USER_REQ');

      final resp = await ApiClient.deleteJson(
        endpoint,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'DELETE_USER');
          return DeleteUserResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'DELETE_USER');
        return DeleteUserResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_USER');
      AppLogger.i(body.toString(), tag: 'DELETE_USER_RES');

      final delResp = DeleteUserResponse.fromJson(body, resp.statusCode);
      return delResp;
    } on ApiException catch (e) {
      AppLogger.e('Delete user error ${e.statusCode} ${e.message}', tag: 'DELETE_USER');
      return DeleteUserResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in deleteUser: $e', tag: 'DELETE_USER');
      return DeleteUserResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<GetCompaniesResponse> getCompanies() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: 'Token bulunamadı');
      }
      final endpoint = AppConstants.getCompanies;
      AppLogger.i('GET $endpoint', tag: 'GET_COMPANIES');
      final resp = await ApiClient.getJson(endpoint, query: {
        'userToken': token,
      });

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_COMPANIES');
          return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: 'Geçersiz yanıt');
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: 'Beklenmeyen yanıt');
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_COMPANIES');
      AppLogger.i(body.toString(), tag: 'GET_COMPANIES_RES');
      return GetCompaniesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: e.message, statusCode: e.statusCode);
    } catch (e) {
      return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: 'Beklenmeyen hata');
    }
  }

  Future<CompanyItem?> getCompanyDetail(int compId) async {
    try {
      final token = StorageService.getToken();
      if (token == null) return null;
      final endpoint = AppConstants.getCompanyFor(compId);
      AppLogger.i('GET $endpoint', tag: 'GET_COMPANY');
      final resp = await ApiClient.getJson(endpoint, query: {'userToken': token});
      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        final jsonData = jsonDecode(responseData);
        body = Map<String, dynamic>.from(jsonData);
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return null;
      }
      final data = body['data'] as Map<String, dynamic>?;
      final comp = data != null ? data['company'] as Map<String, dynamic>? : null;
      if (comp == null) return null;
      return CompanyItem.fromJson(comp);
    } catch (_) {
      return null;
    }
  }

  Future<AddCompanyResponse> addCompany(AddCompanyRequest request) async {
    try {
      final endpoint = AppConstants.addCompany;

      AppLogger.i('POST $endpoint', tag: 'ADD_COMPANY');
      AppLogger.i(request.toJson().toString(), tag: 'ADD_COMPANY_REQ');

      final resp = await ApiClient.postJson(
        endpoint,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_COMPANY');
          return AddCompanyResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_COMPANY');
        return AddCompanyResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_COMPANY');
      AppLogger.i(body.toString(), tag: 'ADD_COMPANY_RES');

      final addCompanyResp = AddCompanyResponse.fromJson(body, resp.statusCode);
      return addCompanyResp;
    } on ApiException catch (e) {
      AppLogger.e('Add company error ${e.statusCode} ${e.message}', tag: 'ADD_COMPANY');
      return AddCompanyResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addCompany: $e', tag: 'ADD_COMPANY');
      return AddCompanyResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<AddCompanyResponse> updateCompany(UpdateCompanyRequest request) async {
    try {
      final endpoint = AppConstants.updateCompany;

      AppLogger.i('POST $endpoint', tag: 'UPDATE_COMPANY');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_COMPANY_REQ');

      final resp = await ApiClient.postJson(
        endpoint,
        data: request.toJson(),
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_COMPANY');
          return AddCompanyResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_COMPANY');
        return AddCompanyResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_COMPANY');
      AppLogger.i(body.toString(), tag: 'UPDATE_COMPANY_RES');

      final updateCompanyResp = AddCompanyResponse.fromJson(body, resp.statusCode);
      return updateCompanyResp;
    } on ApiException catch (e) {
      AppLogger.e('Update company error ${e.statusCode} ${e.message}', tag: 'UPDATE_COMPANY');
      return AddCompanyResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateCompany: $e', tag: 'UPDATE_COMPANY');
      return AddCompanyResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<bool> addCompanyDocument({
    required String userToken,
    required int compId,
    required int documentType,
    required String dataUrl,
  }) async {
    try {
      final endpoint = AppConstants.addCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentType': documentType,
        'file': dataUrl,
      };
      AppLogger.i('POST $endpoint', tag: 'ADD_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'ADD_DOCUMENT_REQ');
      final resp = await ApiClient.postJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      return success;
    } catch (e) {
      AppLogger.e('Add document error: $e', tag: 'ADD_DOCUMENT');
      return false;
    }
  }

  Future<bool> updateCompanyDocument({
    required String userToken,
    required int compId,
    required int documentId,
    required int documentType,
    required String dataUrl,
  }) async {
    try {
      final endpoint = AppConstants.updateCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentID': documentId,
        'documentType': documentType,
        'file': dataUrl,
      };
      AppLogger.i('POST $endpoint', tag: 'UPDATE_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'UPDATE_DOCUMENT_REQ');
      final resp = await ApiClient.postJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Update document error: $e', tag: 'UPDATE_DOCUMENT');
      return false;
    }
  }

  Future<bool> deleteCompanyDocument({
    required String userToken,
    required int compId,
    required int documentId,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentID': documentId,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'DELETE_DOCUMENT_REQ');
      final resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete document error: $e', tag: 'DELETE_DOCUMENT');
      return false;
    }
  }
}
