import 'package:dio/dio.dart';

import 'api_client.dart';
import 'app_constants.dart';
import '../models/support_models.dart';

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
}


