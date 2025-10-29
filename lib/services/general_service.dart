import 'package:dio/dio.dart';

import 'api_client.dart';
import 'app_constants.dart';
import 'remote_config_service.dart';
import '../models/support_models.dart';
import '../models/location_models.dart';
import '../models/company_models.dart';
import '../models/project_models.dart';

class GeneralService {
  Future<List<ServiceItem>> getAllServices() async {
    final Response resp = await ApiClient.getJson(AppConstants.getAllServices);
    final data = resp.data as Map<String, dynamic>;
    final parsed = GetAllServicesResponse.fromJson(data);
    return parsed.services;
  }

  Future<ServiceItem> getServiceDetail(int id) async {
    final Response resp = await ApiClient.getJson(AppConstants.getServiceDetail(id));
    final data = resp.data as Map<String, dynamic>;
    final map = (data['data'] as Map<String, dynamic>?)?['service'] as Map<String, dynamic>?;
    if (map == null) {
      throw ApiException(message: 'Service detail not found');
    }
    return ServiceItem.fromJson(map);
  }

  Future<List<CityItem>> getCities() async {
    final Response resp = await ApiClient.getJson(AppConstants.getCities);
    final body = resp.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['cities'] as List<dynamic>? ?? [])
        .map((e) => CityItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<DistrictItem>> getDistricts(int cityNo) async {
    final Response resp = await ApiClient.getJson(AppConstants.getDistrictsFor(cityNo));
    final body = resp.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['districts'] as List<dynamic>? ?? [])
        .map((e) => DistrictItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<CompanyTypeItem>> getCompanyTypes() async {
    final Response resp = await ApiClient.getJson(AppConstants.getCompanyTypes);
    final body = resp.data as Map<String, dynamic>;
     final code = resp.statusCode;
    final parsed = GetCompanyTypesResponse.fromJson(body, code);
    return parsed.types;
  }

  Future<List<DocumentTypeItem>> getDocumentTypes(int documentType) async {
    final String endpoint = documentType == 2 
        ? AppConstants.getDocumentTypesForImages 
        : AppConstants.getDocumentTypesForDocuments;
    final Response resp = await ApiClient.getJson(endpoint);
    final body = resp.data as Map<String, dynamic>;
    final code = resp.statusCode;
    final parsed = GetDocumentTypesResponse.fromJson(body, code);
    return parsed.types;
  }

  Future<List<TaxPalaceItem>> getTaxPalaces(int cityNo) async {
    final Response resp = await ApiClient.getJson(AppConstants.getTaxPalacesFor(cityNo));
    final body = resp.data as Map<String, dynamic>;
    final code = resp.statusCode;
    final parsed = GetTaxPalacesResponse.fromJson(body, code);
    return parsed.palaces;
  }

  Future<List<AddressTypeItem>> getAddressTypes() async {
    final Response resp = await ApiClient.getJson(AppConstants.getAddressTypes);
    final body = resp.data as Map<String, dynamic>;
    final code = resp.statusCode;
    final parsed = GetAddressTypesResponse.fromJson(body, code);
    return parsed.types;
  }

  Future<List<NaceCodeItem>> getNaceCodes() async {
    try {
      // Remote Config'ten en yeni verileri çek
      await RemoteConfigService.forceRefresh();
      
      // NACE kodu linkini çek
      final String naceUrl = RemoteConfigService.getNaceCodesUrl();
      
      // URL boşsa hata fırlatma
      if (naceUrl.isEmpty) {
        throw ApiException(message: 'NACE URL boş döndürüldü');
      }
      
      final Response resp = await ApiClient.getJson(naceUrl);
      final body = resp.data as Map<String, dynamic>;
      final list = (body['naceCodes'] as List<dynamic>? ?? [])
          .map((e) => NaceCodeItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      // Error log ve varsayılan değer dön
      throw ApiException(message: 'NACE kodları yüklenemedi: $e');
    }
  }

  Future<List<ProjectStatus>> getProjectStatuses() async {
    final Response resp = await ApiClient.getJson(AppConstants.getProjectStatuses);
    final body = resp.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['statuses'] as List<dynamic>? ?? [])
        .map((e) => ProjectStatus.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}



