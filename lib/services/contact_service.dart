import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/user_request_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';

class ContactService {
  Future<SendContactMessageResponse> sendContactMessage(SendContactMessageRequest request) async {
    try {
      final endpoint = AppConstants.sendContactMessage;

      AppLogger.i('POST $endpoint', tag: 'CONTACT_SEND');
      AppLogger.i(request.toJson().toString(), tag: 'CONTACT_SEND_REQ');

      final Response resp = await ApiClient.postJson(
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
          AppLogger.e('Response parse error: $e', tag: 'CONTACT_SEND');
          return SendContactMessageResponse(
            error: true,
            success: false,
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'CONTACT_SEND');
        return SendContactMessageResponse(
          error: true,
          success: false,
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'CONTACT_SEND');
      AppLogger.i(body.toString(), tag: 'CONTACT_SEND_RES');

      return SendContactMessageResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Contact send error ${e.statusCode} ${e.message}', tag: 'CONTACT_SEND');
      return SendContactMessageResponse(
        error: true,
        success: false,
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in sendContactMessage: $e', tag: 'CONTACT_SEND');
      return SendContactMessageResponse(
        error: true,
        success: false,
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<GetContactSubjectsResponse> getContactSubjects() async {
    try {
      final endpoint = AppConstants.getContactSubjects;

      AppLogger.i('GET $endpoint', tag: 'CONTACT_SUBJECTS');

      final Response resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;

      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'CONTACT_SUBJECTS');
          return GetContactSubjectsResponse(
            error: true,
            success: false,
            subjects: const [],
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'CONTACT_SUBJECTS');
        return GetContactSubjectsResponse(
          error: true,
          success: false,
          subjects: const [],
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'CONTACT_SUBJECTS');
      AppLogger.i(body.toString(), tag: 'CONTACT_SUBJECTS_RES');

      return GetContactSubjectsResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Contact subjects error ${e.statusCode} ${e.message}', tag: 'CONTACT_SUBJECTS');
      return GetContactSubjectsResponse(
        error: true,
        success: false,
        subjects: const [],
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in getContactSubjects: $e', tag: 'CONTACT_SUBJECTS');
      return GetContactSubjectsResponse(
        error: true,
        success: false,
        subjects: const [],
      );
    }
  }
}








