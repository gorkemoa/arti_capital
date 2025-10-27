import 'package:dio/dio.dart';
import 'dart:convert';

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
    required int appointmentPriority,
    required int remindID,
    required int titleID,
    List<int>? persons,
    int? appointmentStatus,
    String? appointmentDesc,
    String? appointmentLocation,
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
        'remindID': remindID,
        'titleID': titleID,
        'appointmentTitle': appointmentTitle,
        'appointmentDesc': appointmentDesc ?? '',
        'appointmentLocation': appointmentLocation ?? '',
        'appointmentDate': appointmentDate,
        'appointmentPriority': appointmentPriority,
        if (appointmentStatus != null) 'appointmentStatus': appointmentStatus,
        if (persons != null && persons.isNotEmpty) 'persons': persons,
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

  Future<AddAppointmentResponse> updateAppointment({
    required int compID,
    required int appointmentID,
    required String appointmentTitle,
    required String appointmentDate,
    required int appointmentPriority,
    required int remindID,
    required int titleID,
    List<int>? persons,
    int? appointmentStatus,
    String? appointmentDesc,
    String? appointmentLocation,
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

      final endpoint = AppConstants.updateAppointment;
      AppLogger.i('PUT $endpoint', tag: 'UPDATE_APPOINTMENT');

      final body = {
        'userToken': token,
        'compID': compID,
        'appointmentID': appointmentID,
        'remindID': remindID,
        'titleID': titleID,
        'appointmentTitle': appointmentTitle,
        'appointmentDesc': appointmentDesc ?? '',
        'appointmentLocation': appointmentLocation ?? '',
        'appointmentDate': appointmentDate,
        'appointmentPriority': appointmentPriority,
        if (appointmentStatus != null) 'appointmentStatus': appointmentStatus,
        if (persons != null && persons.isNotEmpty) 'persons': persons,
      };

      final Response resp = await ApiClient.putJson(
        endpoint,
        data: body as Map<String, dynamic>,
      );

      final map = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_APPOINTMENT');
      AppLogger.i(map.toString(), tag: 'UPDATE_APPOINTMENT_RES');
      return AddAppointmentResponse.fromJson(map, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Update appointment error ${e.statusCode} ${e.message}', tag: 'UPDATE_APPOINTMENT');
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

  Future<DeleteAppointmentResponse> deleteAppointment({
    required int appointmentID,
  }) async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return DeleteAppointmentResponse(
          error: true,
          success: false,
          message: 'Token bulunamadı',
          errorMessage: 'Token bulunamadı',
        );
      }

      final endpoint = AppConstants.deleteAppointment;
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_APPOINTMENT');

      final body = {
        'userToken': token,
        'appointmentID': appointmentID,
      };

      final Response resp = await ApiClient.deleteJson(
        endpoint,
        data: body,
      );

      final map = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_APPOINTMENT');
      AppLogger.i(map.toString(), tag: 'DELETE_APPOINTMENT_RES');

      return DeleteAppointmentResponse.fromJson(map, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Delete appointment error ${e.statusCode} ${e.message}', tag: 'DELETE_APPOINTMENT');
      final map = (e.data is Map<String, dynamic>) ? e.data as Map<String, dynamic> : null;
      if (map != null) {
        return DeleteAppointmentResponse.fromJson(map, e.statusCode);
      }
      // For 417 errors, use the exception message directly as it contains the API's error message
      return DeleteAppointmentResponse(
        error: true,
        success: false,
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.statusCode == 417 ? e.message : null,
      );
    }
  }

  Future<GetAppointmentStatusesResponse> getAppointmentStatuses() async {
    try {
      final endpoint = AppConstants.getAppointmentStatuses;
      AppLogger.i('GET $endpoint', tag: 'GET_APPOINTMENT_STATUSES');

      final Response resp = await ApiClient.getJson(endpoint);

      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_APPOINTMENT_STATUSES');
      AppLogger.i(body.toString(), tag: 'GET_APPOINTMENT_STATUSES_RES');

      return GetAppointmentStatusesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get appointment statuses error ${e.statusCode} ${e.message}', tag: 'GET_APPOINTMENT_STATUSES');
      return GetAppointmentStatusesResponse(
        error: true,
        success: false,
        statuses: const <AppointmentStatus>[],
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<GetAppointmentPrioritiesResponse> getAppointmentPriorities() async {
    try {
      final endpoint = AppConstants.getAppointmentPriorities;
      AppLogger.i('GET $endpoint', tag: 'GET_APPOINTMENT_PRIORITIES');

      final Response resp = await ApiClient.getJson(endpoint);

      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_APPOINTMENT_PRIORITIES');
      AppLogger.i(body.toString(), tag: 'GET_APPOINTMENT_PRIORITIES_RES');

      return GetAppointmentPrioritiesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get appointment priorities error ${e.statusCode} ${e.message}', tag: 'GET_APPOINTMENT_PRIORITIES');
      return GetAppointmentPrioritiesResponse(
        error: true,
        success: false,
        priorities: const <AppointmentPriority>[],
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<GetAppointmentRemindTypesResponse> getAppointmentRemindTypes() async {
    try {
      final endpoint = AppConstants.getAppointmentRemindTypes;
      AppLogger.i('GET $endpoint', tag: 'GET_APPOINTMENT_REMIND_TYPES');

      final Response resp = await ApiClient.getJson(endpoint);

      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_APPOINTMENT_REMIND_TYPES');
      AppLogger.i(body.toString(), tag: 'GET_APPOINTMENT_REMIND_TYPES_RES');

      return GetAppointmentRemindTypesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get appointment remind types error ${e.statusCode} ${e.message}', tag: 'GET_APPOINTMENT_REMIND_TYPES');
      return GetAppointmentRemindTypesResponse(
        error: true,
        success: false,
        types: const <AppointmentRemindType>[],
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<GetAppointmentTitlesResponse> getAppointmentTitles() async {
    try {
      final endpoint = AppConstants.getAppointmentTitles;
      AppLogger.i('GET $endpoint', tag: 'GET_APPOINTMENT_TITLES');

      final Response resp = await ApiClient.getJson(endpoint);

      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_APPOINTMENT_TITLES');
      AppLogger.i(body.toString(), tag: 'GET_APPOINTMENT_TITLES_RES');

      return GetAppointmentTitlesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Get appointment titles error ${e.statusCode} ${e.message}', tag: 'GET_APPOINTMENT_TITLES');
      return GetAppointmentTitlesResponse(
        error: true,
        success: false,
        titles: const <AppointmentTitle>[],
        message: e.message ?? 'Beklenmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPersons() async {
    try {
      final endpoint = AppConstants.getPersons;
      AppLogger.i('GET $endpoint', tag: 'GET_PERSONS');

      final resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          body = Map<String, dynamic>.from(jsonDecode(responseData));
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_PERSONS');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'GET_PERSONS');
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_PERSONS');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final personsJson = (data['persons'] as List<dynamic>?) ?? [];
      return personsJson
          .map((e) {
            final person = e as Map<String, dynamic>;
            return {
              'id': person['userID'] as int? ?? 0,
              'name': person['userName'] as String? ?? 'Unknown',
              'type': person['userType'] as String? ?? '',
            };
          })
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get persons error ${e.statusCode} ${e.message}', tag: 'GET_PERSONS');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getPersons: $e', tag: 'GET_PERSONS');
      return [];
    }
  }
}


