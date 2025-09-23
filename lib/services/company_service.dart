import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'app_constants.dart';
import 'logger.dart';
import 'storage_service.dart';
import '../models/company_models.dart';

class CompanyService {
  const CompanyService();

  Future<GetCompaniesResponse> getCompanies() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        return GetCompaniesResponse(error: true, success: false, companies: const [], errorMessage: 'Token bulunamadı');
      }
      final endpoint = AppConstants.getCompanies;
      AppLogger.i('GET $endpoint', tag: 'GET_COMPANIES');
      final Response resp = await ApiClient.getJson(endpoint, query: {
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
      final Response resp = await ApiClient.getJson(endpoint, query: {'userToken': token});
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

      final Response resp = await ApiClient.putJson(
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
    int? partnerID,
  }) async {
    try {
      final endpoint = AppConstants.addCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentType': documentType,
        'file': dataUrl,
        'partnerID': partnerID ?? 0,
      };
      AppLogger.i('POST $endpoint', tag: 'ADD_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'ADD_DOCUMENT_REQ');
      final Response resp = await ApiClient.postJson(endpoint, data: payload);
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
    int? partnerID,
  }) async {
    try {
      final endpoint = AppConstants.updateCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentID': documentId,
        'documentType': documentType,
        'file': dataUrl,
        'partnerID': partnerID ?? 0,
      };
      AppLogger.i('POST $endpoint', tag: 'UPDATE_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'UPDATE_DOCUMENT_REQ');
      final Response resp = await ApiClient.postJson(endpoint, data: payload);
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
    int? partnerID,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentID': documentId,
        'partnerID': partnerID ?? 0,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'DELETE_DOCUMENT_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete document error: $e', tag: 'DELETE_DOCUMENT');
      return false;
    }
  }

  Future<AddPartnerResponse> addCompanyPartner(AddPartnerRequest request) async {
    try {
      final endpoint = AppConstants.addPartner;

      AppLogger.i('POST $endpoint', tag: 'ADD_PARTNER');
      AppLogger.i(request.toJson().toString(), tag: 'ADD_PARTNER_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'ADD_PARTNER');
          return AddPartnerResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_PARTNER');
        return AddPartnerResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_PARTNER');
      AppLogger.i(body.toString(), tag: 'ADD_PARTNER_RES');

      final addPartnerResp = AddPartnerResponse.fromJson(body, resp.statusCode);
      return addPartnerResp;
    } on ApiException catch (e) {
      AppLogger.e('Add partner error ${e.statusCode} ${e.message}', tag: 'ADD_PARTNER');
      return AddPartnerResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addCompanyPartner: $e', tag: 'ADD_PARTNER');
      return AddPartnerResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<UpdatePartnerResponse> updateCompanyPartner(UpdatePartnerRequest request) async {
    try {
      final endpoint = AppConstants.updatePartner;

      AppLogger.i('POST $endpoint', tag: 'UPDATE_PARTNER');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_PARTNER_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_PARTNER');
          return UpdatePartnerResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_PARTNER');
        return UpdatePartnerResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_PARTNER');
      AppLogger.i(body.toString(), tag: 'UPDATE_PARTNER_RES');

      final updateResp = UpdatePartnerResponse.fromJson(body, resp.statusCode);
      return updateResp;
    } on ApiException catch (e) {
      AppLogger.e('Update partner error ${e.statusCode} ${e.message}', tag: 'UPDATE_PARTNER');
      return UpdatePartnerResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateCompanyPartner: $e', tag: 'UPDATE_PARTNER');
      return UpdatePartnerResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<bool> deleteCompanyPartner({
    required String userToken,
    required int compId,
    required int partnerId,
  }) async {
    try {
      final endpoint = AppConstants.deletePartner;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'partnerID': partnerId,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_PARTNER');
      AppLogger.i(payload.toString(), tag: 'DELETE_PARTNER_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete partner error: $e', tag: 'DELETE_PARTNER');
      return false;
    }
  }
}


