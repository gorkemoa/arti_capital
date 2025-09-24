import 'company_models.dart';

class DocumentsGroupItem {
  final int compID;
  final String companyName;
  final String companyType;
  final List<CompanyDocumentItem> documents;

  DocumentsGroupItem({
    required this.compID,
    required this.companyName,
    required this.companyType,
    this.documents = const [],
  });

  factory DocumentsGroupItem.fromJson(Map<String, dynamic> json) {
    final docs = (json['documents'] as List<dynamic>? ?? [])
        .map((e) => CompanyDocumentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return DocumentsGroupItem(
      compID: (json['compID'] as num?)?.toInt() ?? 0,
      companyName: json['companyName'] as String? ?? '',
      companyType: json['companyType'] as String? ?? '',
      documents: docs,
    );
  }
}

class GetMyDocumentsResponse {
  final bool error;
  final bool success;
  final List<DocumentsGroupItem> compDocs;
  final List<DocumentsGroupItem> userDocs;
  final String? errorMessage;
  final int? statusCode;

  GetMyDocumentsResponse({
    required this.error,
    required this.success,
    required this.compDocs,
    required this.userDocs,
    this.errorMessage,
    this.statusCode,
  });

  factory GetMyDocumentsResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final comp = (data != null ? data['compDocs'] as List<dynamic>? : null) ?? [];
    final user = (data != null ? data['userDocs'] as List<dynamic>? : null) ?? [];
    return GetMyDocumentsResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      compDocs: comp.map((e) => DocumentsGroupItem.fromJson(e as Map<String, dynamic>)).toList(),
      userDocs: user.map((e) => DocumentsGroupItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


