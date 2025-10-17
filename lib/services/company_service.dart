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
    String? documentDesc,
    String? documentValidityDate,
    String? documentLink,
  }) async {
    try {
      final endpoint = AppConstants.addCompanyDocument;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'documentType': documentType,
        'file': dataUrl,
        'partnerID': partnerID ?? 0,
        'documentDesc': documentDesc ?? '',
        'documentValidityDate': documentValidityDate ?? '',
        'documentLink': documentLink ?? '',
      };
      AppLogger.i('POST $endpoint', tag: 'ADD_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'ADD_DOCUMENT_REQ');
      final Response resp = await ApiClient.postJson(endpoint, data: payload);
      
      AppLogger.i('Response: ${resp.data}', tag: 'ADD_DOCUMENT_RESP');
      
      // Response String olarak dönebilir, kontrol et
      if (resp.data is String) {
        // String response'u parse et
        final jsonData = jsonDecode(resp.data as String);
        final success = !(jsonData['error'] as bool? ?? true);
        AppLogger.i('Success: $success', tag: 'ADD_DOCUMENT');
        return success;
      } else {
        final body = resp.data as Map<String, dynamic>;
        final success = !(body['error'] as bool? ?? true);
        AppLogger.i('Success: $success', tag: 'ADD_DOCUMENT');
        return success;
      }
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
    String? documentDesc,
    String? documentValidityDate,
    String? documentLink,
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
        'documentDesc': documentDesc ?? '',
        'documentValidityDate': documentValidityDate ?? '',
        'documentLink': documentLink ?? '',
      };
      AppLogger.i('POST $endpoint', tag: 'UPDATE_DOCUMENT');
      AppLogger.i(payload.toString(), tag: 'UPDATE_DOCUMENT_REQ');
      final Response resp = await ApiClient.postJson(endpoint, data: payload);
      
      AppLogger.i('Response: ${resp.data}', tag: 'UPDATE_DOCUMENT_RESP');
      
      // Response String olarak dönebilir, kontrol et
      if (resp.data is String) {
        final jsonData = jsonDecode(resp.data as String);
        final success = !(jsonData['error'] as bool? ?? true);
        AppLogger.i('Success: $success', tag: 'UPDATE_DOCUMENT');
        return success;
      } else {
        final body = resp.data as Map<String, dynamic>;
        final success = !(body['error'] as bool? ?? true);
        AppLogger.i('Success: $success', tag: 'UPDATE_DOCUMENT');
        return success;
      }
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

  Future<AddCompanyAddressResponse> addCompanyAddress(AddCompanyAddressRequest request) async {
    try {
      final endpoint = AppConstants.addCompanyAddress;
      AppLogger.i('POST $endpoint', tag: 'ADD_ADDRESS');
      AppLogger.i(request.toJson().toString(), tag: 'ADD_ADDRESS_REQ');

      final Response resp = await ApiClient.postJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'ADD_ADDRESS');
          return AddCompanyAddressResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'ADD_ADDRESS');
        return AddCompanyAddressResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_ADDRESS');
      AppLogger.i(body.toString(), tag: 'ADD_ADDRESS_RES');

      return AddCompanyAddressResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Add address error ${e.statusCode} ${e.message}', tag: 'ADD_ADDRESS');
      return AddCompanyAddressResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in addCompanyAddress: $e', tag: 'ADD_ADDRESS');
      return AddCompanyAddressResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<UpdateCompanyAddressResponse> updateCompanyAddress(UpdateCompanyAddressRequest request) async {
    try {
      final endpoint = AppConstants.updateCompanyAddress;
      AppLogger.i('POST $endpoint', tag: 'UPDATE_ADDRESS');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_ADDRESS_REQ');

      final Response resp = await ApiClient.putJson(endpoint, data: request.toJson());

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_ADDRESS');
          return UpdateCompanyAddressResponse(
            error: true,
            success: false,
            message: 'Sunucudan geçersiz yanıt alındı',
            errorMessage: 'Sunucudan geçersiz yanıt alındı',
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        AppLogger.e('Unexpected response type: ${responseData.runtimeType}', tag: 'UPDATE_ADDRESS');
        return UpdateCompanyAddressResponse(
          error: true,
          success: false,
          message: 'Sunucudan beklenmeyen yanıt türü alındı',
          errorMessage: 'Sunucudan beklenmeyen yanıt türü alındı',
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_ADDRESS');
      AppLogger.i(body.toString(), tag: 'UPDATE_ADDRESS_RES');

      return UpdateCompanyAddressResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('Update address error ${e.statusCode} ${e.message}', tag: 'UPDATE_ADDRESS');
      return UpdateCompanyAddressResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bir hata oluştu',
        errorMessage: e.message,
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error in updateCompanyAddress: $e', tag: 'UPDATE_ADDRESS');
      return UpdateCompanyAddressResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen bir hata oluştu',
        errorMessage: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  Future<bool> deleteCompanyAddress({
    required String userToken,
    required int compId,
    required int addressId,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompanyAddress;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'addressID': addressId,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_ADDRESS');
      AppLogger.i(payload.toString(), tag: 'DELETE_ADDRESS_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete address error: $e', tag: 'DELETE_ADDRESS');
      return false;
    }
  }

  Future<AddCompanyBankResponse> addCompanyBank(AddCompanyBankRequest request) async {
    try {
      final endpoint = AppConstants.addCompanyBank;

      AppLogger.i('POST $endpoint', tag: 'ADD_COMPANY_BANK');
      AppLogger.i(request.toJson().toString(), tag: 'ADD_COMPANY_BANK_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'ADD_COMPANY_BANK');
          return AddCompanyBankResponse(
            error: true,
            success: false,
            message: 'Geçersiz yanıt',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return AddCompanyBankResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_COMPANY_BANK');
      AppLogger.i(body.toString(), tag: 'ADD_COMPANY_BANK_RES');

      return AddCompanyBankResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return AddCompanyBankResponse(
        error: true,
        success: false,
        message: e.message ?? 'API Hatası',
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Add company bank error: $e', tag: 'ADD_COMPANY_BANK');
      return AddCompanyBankResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen hata',
      );
    }
  }

  Future<UpdateCompanyBankResponse> updateCompanyBank(UpdateCompanyBankRequest request) async {
    try {
      final endpoint = AppConstants.updateCompanyBank;

      AppLogger.i('POST $endpoint', tag: 'UPDATE_COMPANY_BANK');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_COMPANY_BANK_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_COMPANY_BANK');
          return UpdateCompanyBankResponse(
            error: true,
            success: false,
            message: 'Geçersiz yanıt',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return UpdateCompanyBankResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_COMPANY_BANK');
      AppLogger.i(body.toString(), tag: 'UPDATE_COMPANY_BANK_RES');

      return UpdateCompanyBankResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return UpdateCompanyBankResponse(
        error: true,
        success: false,
        message: e.message ?? 'API Hatası',
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Update company bank error: $e', tag: 'UPDATE_COMPANY_BANK');
      return UpdateCompanyBankResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen hata',
      );
    }
  }

  Future<GetBanksResponse> getBanks() async {
    try {
      final endpoint = AppConstants.getBanks;
      AppLogger.i('GET $endpoint', tag: 'GET_BANKS');
      final Response resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_BANKS');
          return GetBanksResponse(
            error: true,
            success: false,
            banks: const [],
            errorMessage: 'Geçersiz yanıt',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return GetBanksResponse(
          error: true,
          success: false,
          banks: const [],
          errorMessage: 'Beklenmeyen yanıt',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_BANKS');
      AppLogger.i(body.toString(), tag: 'GET_BANKS_RES');
      return GetBanksResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return GetBanksResponse(
        error: true,
        success: false,
        banks: const [],
        errorMessage: e.message ?? 'API Hatası',
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Get banks error: $e', tag: 'GET_BANKS');
      return GetBanksResponse(
        error: true,
        success: false,
        banks: const [],
        errorMessage: 'Beklenmeyen hata',
      );
    }
  }

  Future<GetPasswordTypesResponse> getPasswordTypes() async {
    try {
      final endpoint = AppConstants.getPasswordTypes;
      AppLogger.i('GET $endpoint', tag: 'GET_PASSWORD_TYPES');
      final Response resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_PASSWORD_TYPES');
          return GetPasswordTypesResponse(
            error: true,
            success: false,
            types: const [],
            errorMessage: 'Geçersiz yanıt',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return GetPasswordTypesResponse(
          error: true,
          success: false,
          types: const [],
          errorMessage: 'Beklenmeyen yanıt',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_PASSWORD_TYPES');
      AppLogger.i(body.toString(), tag: 'GET_PASSWORD_TYPES_RES');
      return GetPasswordTypesResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      return GetPasswordTypesResponse(
        error: true,
        success: false,
        types: const [],
        errorMessage: e.message ?? 'API Hatası',
        statusCode: e.statusCode,
      );
    } catch (e) {
      AppLogger.e('Get password types error: $e', tag: 'GET_PASSWORD_TYPES');
      return GetPasswordTypesResponse(
        error: true,
        success: false,
        types: const [],
        errorMessage: 'Beklenmeyen hata',
      );
    }
  }

  Future<AddCompanyPasswordResponse> addCompanyPassword(AddCompanyPasswordRequest request) async {
    try {
      final endpoint = AppConstants.addCompanyPassword;

      AppLogger.i('POST $endpoint', tag: 'ADD_PASSWORD');
      AppLogger.i(request.toJson().toString(), tag: 'ADD_PASSWORD_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'ADD_PASSWORD');
          return AddCompanyPasswordResponse(
            error: true,
            success: false,
            message: 'Geçersiz yanıt formatı',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return AddCompanyPasswordResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt formatı',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'ADD_PASSWORD');
      AppLogger.i(body.toString(), tag: 'ADD_PASSWORD_RES');

      return AddCompanyPasswordResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('API error: ${e.message}', tag: 'ADD_PASSWORD');
      return AddCompanyPasswordResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bilinmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    } catch (e) {
      AppLogger.e('Unexpected error: $e', tag: 'ADD_PASSWORD');
      return AddCompanyPasswordResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen hata',
        errorMessage: 'Beklenmeyen hata',
      );
    }
  }

  Future<UpdateCompanyPasswordResponse> updateCompanyPassword(UpdateCompanyPasswordRequest request) async {
    try {
      final endpoint = AppConstants.updateCompanyPassword;

      AppLogger.i('POST $endpoint', tag: 'UPDATE_PASSWORD');
      AppLogger.i(request.toJson().toString(), tag: 'UPDATE_PASSWORD_REQ');

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
          AppLogger.e('Response parse error: $e', tag: 'UPDATE_PASSWORD');
          return UpdateCompanyPasswordResponse(
            error: true,
            success: false,
            message: 'Geçersiz yanıt formatı',
            statusCode: resp.statusCode,
          );
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return UpdateCompanyPasswordResponse(
          error: true,
          success: false,
          message: 'Beklenmeyen yanıt formatı',
          statusCode: resp.statusCode,
        );
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'UPDATE_PASSWORD');
      AppLogger.i(body.toString(), tag: 'UPDATE_PASSWORD_RES');

      return UpdateCompanyPasswordResponse.fromJson(body, resp.statusCode);
    } on ApiException catch (e) {
      AppLogger.e('API error: ${e.message}', tag: 'UPDATE_PASSWORD');
      return UpdateCompanyPasswordResponse(
        error: true,
        success: false,
        message: e.message ?? 'Bilinmeyen hata',
        statusCode: e.statusCode,
        errorMessage: e.message,
      );
    } catch (e) {
      AppLogger.e('Unexpected error: $e', tag: 'UPDATE_PASSWORD');
      return UpdateCompanyPasswordResponse(
        error: true,
        success: false,
        message: 'Beklenmeyen hata',
        errorMessage: 'Beklenmeyen hata',
      );
    }
  }

  Future<bool> deleteCompanyPassword({
    required String userToken,
    required int compId,
    required int passID,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompanyPassword;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'passID': passID,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_PASSWORD');
      AppLogger.i(payload.toString(), tag: 'DELETE_PASSWORD_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_PASSWORD');
      AppLogger.i(body.toString(), tag: 'DELETE_PASSWORD_RES');
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete password error: $e', tag: 'DELETE_PASSWORD');
      return false;
    }
  }

  Future<bool> deleteCompanyBank({
    required String userToken,
    required int compId,
    required int cbID,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompanyBank;
      final payload = {
        'userToken': userToken,
        'compID': compId,
        'cbID': cbID,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_BANK');
      AppLogger.i(payload.toString(), tag: 'DELETE_BANK_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete bank error: $e', tag: 'DELETE_BANK');
      return false;
    }
  }

  Future<bool> deleteCompany({
    required String userToken,
    required int compId,
  }) async {
    try {
      final endpoint = AppConstants.deleteCompany;
      final payload = {
        'userToken': userToken,
        'compID': compId,
      };
      AppLogger.i('DELETE $endpoint', tag: 'DELETE_COMPANY');
      AppLogger.i(payload.toString(), tag: 'DELETE_COMPANY_REQ');
      final Response resp = await ApiClient.deleteJson(endpoint, data: payload);
      final body = resp.data as Map<String, dynamic>;
      AppLogger.i('Status ${resp.statusCode}', tag: 'DELETE_COMPANY');
      AppLogger.i(body.toString(), tag: 'DELETE_COMPANY_RES');
      return body['success'] as bool? ?? false;
    } catch (e) {
      AppLogger.e('Delete company error: $e', tag: 'DELETE_COMPANY');
      return false;
    }
  }

  Future<List<CompanyAddressItem>> getCompanyAddresses(int compId) async {
    try {
      final endpoint = AppConstants.getCompanyAddressesFor(compId);
      AppLogger.i('GET $endpoint', tag: 'GET_COMP_ADDRESSES');
      
      final Response resp = await ApiClient.getJson(endpoint);

      dynamic responseData = resp.data;
      Map<String, dynamic> body;
      if (responseData is String) {
        try {
          final jsonData = jsonDecode(responseData);
          body = Map<String, dynamic>.from(jsonData);
        } catch (e) {
          AppLogger.e('Response parse error: $e', tag: 'GET_COMP_ADDRESSES');
          return [];
        }
      } else if (responseData is Map<String, dynamic>) {
        body = responseData;
      } else {
        return [];
      }

      AppLogger.i('Status ${resp.statusCode}', tag: 'GET_COMP_ADDRESSES');
      AppLogger.i(body.toString(), tag: 'GET_COMP_ADDRESSES_RES');

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return [];
      
      final addressesJson = (data['addresses'] as List<dynamic>?) ?? [];
      return addressesJson
          .map((e) => CompanyAddressItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      AppLogger.e('Get addresses error ${e.statusCode} ${e.message}', tag: 'GET_COMP_ADDRESSES');
      return [];
    } catch (e) {
      AppLogger.e('Unexpected error in getCompanyAddresses: $e', tag: 'GET_COMP_ADDRESSES');
      return [];
    }
  }
}
