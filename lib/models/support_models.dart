// Service Document Model
class ServiceDocument {
  final int documentID;
  final String documentName;
  final String statusText;
  final bool isRequired;

  ServiceDocument({
    required this.documentID,
    required this.documentName,
    required this.statusText,
    required this.isRequired,
  });

  factory ServiceDocument.fromJson(Map<String, dynamic> json) {
    return ServiceDocument(
      documentID: json['documentID'] is String ? int.tryParse(json['documentID']) ?? 0 : (json['documentID'] ?? 0) as int,
      documentName: (json['documentName'] ?? '').toString(),
      statusText: (json['statusText'] ?? '').toString(),
      isRequired: (json['isRequired'] ?? false) as bool,
    );
  }
}



// Service Item Model
class ServiceItem {
  final int serviceID;
  final String serviceName;
  final String serviceDesc;
  final String serviceIcon;
  final List<ServiceDocument> documents;

  ServiceItem({
    required this.serviceID,
    required this.serviceName,
    required this.serviceDesc,
    required this.serviceIcon,
    List<ServiceDocument>? documents,
  })  : documents = documents ?? const <ServiceDocument>[];

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final rawDocuments = json['documents'];
    final List<ServiceDocument> parsedDocuments;
    if (rawDocuments is List) {
      parsedDocuments = rawDocuments
          .whereType<Map<String, dynamic>>()
          .map((e) => ServiceDocument.fromJson(e))
          .toList();
    } else {
      parsedDocuments = const <ServiceDocument>[];
    }

    return ServiceItem(
      serviceID: json['serviceID'] is String ? int.tryParse(json['serviceID']) ?? 0 : (json['serviceID'] ?? 0) as int,
      serviceName: (json['serviceName'] ?? '').toString(),
      serviceDesc: (json['serviceDesc'] ?? '').toString(),
      serviceIcon: (json['serviceIcon'] ?? '').toString(),
      documents: parsedDocuments,
    );
  }
}

// Get All Services Response
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
