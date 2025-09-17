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
}


