import 'package:dio/dio.dart';

import '../models/appointment_models.dart';
import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';

class AppointmentsService {
  Future<GetAppointmentsResponse> getAppointments() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetAppointmentsResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
          appointments: const <AppointmentItem>[],
          totalCount: 0,
          errorMessage: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.getAppointments;
      AppLogger.i('GET $endpoint', tag: 'GET_APPOINTMENTS');

      final Response resp = await ApiClient.getJson(
        endpoint,
        query: {'userToken': token},
      );

      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_APPOINTMENTS');
      AppLogger.i(body.toString(), tag: 'GET_APPOINTMENTS_RES');

      return GetAppointmentsResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Appointments error ${e.statusCode} ${e.message}', tag: 'GET_APPOINTMENTS');
      return GetAppointmentsResponse(
        error: true,
        success: false,
        message: e.message ?? 'Beklenmeyen hata',
        appointments: const <AppointmentItem>[],
        totalCount: 0,
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<AddAppointmentResponse> addAppointment({
    required int compID,
    required String appointmentTitle,
    required String appointmentDate,
    int? appointmentStatus,
    String? appointmentDesc,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return AddAppointmentResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
          errorMessage: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.addAppointment;
      AppLogger.i('POST $endpoint', tag: 'ADD_APPOINTMENT');

      final body = {
        'userToken': token,
        'compID': compID,
        'appointmentTitle': appointmentTitle,
        'appointmentDesc': appointmentDesc ?? '',
        'appointmentDate': appointmentDate,
        if (appointmentStatus != null) 'appointmentStatus': appointmentStatus,
      };

      final Response resp = await ApiClient.postJson(
        endpoint,
        data: body,
      );

      final map = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_APPOINTMENT');
      AppLogger.i(map.toString(), tag: 'ADD_APPOINTMENT_RES');

      return AddAppointmentResponse.fromJson(map, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add appointment error ${e.statusCode} ${e.message}', tag: 'ADD_APPOINTMENT');
      final map = (e.data is Map<String, dynamic>) ? e.data as Map<String, dynamic> : null;
      if (map != null) {
        return AddAppointmentResponse.fromJson(map, e.statusCode);
      }
      return AddAppointmentResponse(
        error: true,
        success: false,
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }
}


