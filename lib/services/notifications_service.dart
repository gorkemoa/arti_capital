import 'dart:convert';

import '../models/notification_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class NotificationsService {
  Future<GetNotificationsResponse> getNotifications() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetNotificationsResponse(
          error: true,
          success: false,
          notifications: const [],
          errorMessage: 'Token bulunamadı',
        );
      }

      final req = { 'userToken': token };

      AppLogger.i('PUT ${AppConstants.getNotifications}', tag: 'GET_NOTIFS');
      AppLogger.i(req.toString(), tag: 'GET_NOTIFS_REQ');

      final resp = await ApiClient.putJson(
        AppConstants.getNotifications,
        data: req,
      );

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_NOTIFS');
          return GetNotificationsResponse(
            error: true,
            success: false,
            notifications: const [],
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_NOTIFS');
        return GetNotificationsResponse(
          error: true,
          success: false,
          notifications: const [],
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_NOTIFS');
      AppLogger.i(body.toString(), tag: 'GET_NOTIFS_RES');

      return GetNotificationsResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get notifications error ${e.statusCode} ${e.message}', tag: 'GET_NOTIFS');
      return GetNotificationsResponse(
        error: true,
        success: false,
        notifications: const [],
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in getNotifications: $e', tag: 'GET_NOTIFS');
      return GetNotificationsResponse(
        error: true,
        success: false,
        notifications: const [],
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }
}


