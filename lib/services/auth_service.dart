

import '../models/login_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class AuthService {
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      AppLogger.i('PUT ${AppConstants.login}', tag: 'AUTH');
      AppLogger.i(request.toJson().toString(), tag: 'AUTH_REQ');
      final resp = await ApiClient.postJson(
        AppConstants.login,
        data: request.toJson(),
      );
      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'AUTH');
      AppLogger.i(body.toString(), tag: 'AUTH_RES');
      
      final loginResponse = LoginResponse.fromJson(body, resp.statusCode);
      
      // Giriş başarılı ise token ve user ID'yi kaydet
      if (loginResponse.success && loginResponse.data != null) {
        await StorageService.saveToken(loginResponse.data!.token);
        await StorageService.saveUserId(loginResponse.data!.userId);
      }
      
      return loginResponse;
    } on ApiException catch (e) {
      AppLogger.e('Auth error ${e.statusCode} ${e.message}', tag: 'AUTH');
      // 417 gibi durumlarda doğrudan hata mesajını döndür
      return LoginResponse(
        error: true,
        success: false,
        data: null,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    }
  }



  Future<void> logout() async {
    await StorageService.clearUserData();
  }

  bool isLoggedIn() {
    return StorageService.isLoggedIn();
  }
}


