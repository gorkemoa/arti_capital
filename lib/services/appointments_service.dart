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
}


