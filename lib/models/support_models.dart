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

// Duty Model
class DutyItem {
  final int dutyID;
  final String dutyName;
  final String dutyDesc;

  DutyItem({required this.dutyID, required this.dutyName, required this.dutyDesc});

  factory DutyItem.fromJson(Map<String, dynamic> json) {
    return DutyItem(
      dutyID: json['dutyID'] is String ? int.tryParse(json['dutyID']) ?? 0 : (json['dutyID'] ?? 0) as int,
      dutyName: (json['dutyName'] ?? '').toString(),
      dutyDesc: (json['dutyDesc'] ?? '').toString(),
    );
  }
}

// Service Item Model
class ServiceItem {
  final int serviceID;
  final String serviceName;
  final String serviceDesc;
  final String serviceIcon;
  final List<DutyItem> duties;
  final List<ServiceDocument> documents;

  ServiceItem({
    required this.serviceID,
    required this.serviceName,
    required this.serviceDesc,
    required this.serviceIcon,
    List<DutyItem>? duties,
    List<ServiceDocument>? documents,
  })  : duties = duties ?? const <DutyItem>[],
        documents = documents ?? const <ServiceDocument>[];

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final rawDuties = json['duties'];
    final List<DutyItem> parsedDuties;
    if (rawDuties is List) {
      parsedDuties = rawDuties
          .whereType<Map<String, dynamic>>()
          .map((e) => DutyItem.fromJson(e))
          .toList();
    } else {
      parsedDuties = const <DutyItem>[];
    }

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
      duties: parsedDuties,
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
