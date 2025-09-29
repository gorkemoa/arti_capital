import 'package:dio/dio.dart';

import 'api_client.dart';
import 'app_constants.dart';
import '../models/support_models.dart';
import '../models/location_models.dart';
import '../models/company_models.dart';

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

  Future<List<DocumentTypeItem>> getDocumentTypes() async {
    final Response resp = await ApiClient.getJson(AppConstants.getDocumentTypes);
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
    // Direkt statik JSON URL'inden çekiyoruz
    final Response resp = await ApiClient.getJson(
      'https://projects.office701.com/arti-capital/upload/static/nace_codes.json',
    );
    final body = resp.data as Map<String, dynamic>;
    final list = (body['naceCodes'] as List<dynamic>? ?? [])
        .map((e) => NaceCodeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }
}


