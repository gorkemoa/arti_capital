

import '../models/login_models.dart';
import '../models/two_factor_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';
import 'notifications_service.dart';

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
        // Last login zamanını kaydet
        await StorageService.saveLastLoginAt(DateTime.now());
        
        // User ID'ye göre FCM topic'e abone ol
        await NotificationsService.subscribeToUserTopic(loginResponse.data!.userId);
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
    // Çıkış yaparken kullanıcı topic'inden abone ol
    final userId = StorageService.getUserId();
    if (userId != null) {
      await NotificationsService.unsubscribeFromUserTopic(userId);
    }
    
    await StorageService.clearUserData();
  }

  bool isLoggedIn() {
    return StorageService.isLoggedIn();
  }
}

extension TwoFactorAuth on AuthService {
  Future<AuthCodeSendResponse> sendAuthCode({required int sendType}) async {
    final token = StorageService.getToken();
    if (token == null) {
      return AuthCodeSendResponse(
        error: true,
        success: false,
        message: 'Token bulunamadı',
        data: null,
        statusCode: 401,
        errorMessage: 'Token bulunamadı',
      );
    }

    try {
      final req = AuthCodeSendRequest(userToken: token, sendType: sendType);
      AppLogger.i('POST ${AppConstants.authCodeSend}', tag: '2FA_SEND');
      final resp = await ApiClient.postJson(
        AppConstants.authCodeSend,
        data: req.toJson(),
      );
      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: '2FA_SEND');
      AppLogger.i(body.toString(), tag: '2FA_SEND_RES');
      return AuthCodeSendResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return AuthCodeSendResponse(
        error: true,
        success: false,
        message: e.message,
        data: null,
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<CheckCodeResponse> checkAuthCode({required String code, required String codeToken}) async {
    try {
      AppLogger.i('POST ${AppConstants.checkCode}', tag: '2FA_CHECK');
      final resp = await ApiClient.postJson(
        AppConstants.checkCode,
        data: CheckCodeRequest(code: code, codeToken: codeToken).toJson(),
      );
      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: '2FA_CHECK');
      AppLogger.i(body.toString(), tag: '2FA_CHECK_RES');
      return CheckCodeResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return CheckCodeResponse(
        error: true,
        success: false,
        message: e.message,
        data: null,
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }
}


