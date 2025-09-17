class ServiceItem {
  final int serviceID;
  final String serviceName;
  final String serviceDesc;
  final String serviceIcon;

  ServiceItem({required this.serviceID, required this.serviceName, required this.serviceDesc, required this.serviceIcon});

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceID: json['serviceID'] is String ? int.tryParse(json['serviceID']) ?? 0 : (json['serviceID'] ?? 0) as int,
      serviceName: (json['serviceName'] ?? '').toString(),
      serviceDesc: (json['serviceDesc'] ?? '').toString(),
      serviceIcon: (json['serviceIcon'] ?? '').toString(),
    );
  }
}

class GetAllServicesResponse {
  final bool error;
  final bool success;
  final List<ServiceItem> services;

  GetAllServicesResponse({required this.error, required this.success, required this.services});

  factory GetAllServicesResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?);
    final list = (data != null ? data['services'] : null) as List<dynamic>?;
    final services = (list ?? const <dynamic>[])
        .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return GetAllServicesResponse(
      error: (json['error'] ?? false) as bool,
      success: (json['success'] ?? false) as bool,
      services: services,
    );
  }
}


