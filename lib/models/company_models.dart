class CompanyItem {
  final int compID;
  final String compName;
  final String compCity;
  final String compDistrict;
  final int compCityID;
  final int compDistrictID;
  final String compAddress;
  final String? compTaxNo;
  final int? compTaxPalaceID; 
  final String? compTaxPalace;
  final String? compMersisNo;
  final String? compType;
  final String compLogo; // data url veya http url
  final String createdate;
  final List<CompanyDocumentItem> documents;
  final List<PartnerItem>partners;

  CompanyItem({
    required this.compID,
    required this.compName,
    required this.compCity,
    required this.compDistrict,
    required this.compCityID,
    required this.compDistrictID,
    required this.compAddress,
    this.compTaxNo,
    this.compTaxPalace,
    this.compTaxPalaceID,
    this.compMersisNo,
    this.compType,
    required this.compLogo,
    required this.createdate,
    this.documents = const [],
    this.partners = const [],
  });

  factory CompanyItem.fromJson(Map<String, dynamic> json) => CompanyItem(
        compID: (json['compID'] as num).toInt(),
        compName: json['compName'] as String? ?? '',
        compCity: json['compCity'] as String? ?? '',
        compDistrict: json['compDistrict'] as String? ?? '',
        compCityID: (json['compCityID'] as num?)?.toInt() ?? 0,
        compDistrictID: (json['compDistrictID'] as num?)?.toInt() ?? 0,
        compAddress: json['compAddress'] as String? ?? '',
        compTaxNo: json['compTaxNo'] as String?,
        compTaxPalace: json['compTaxPalace'] as String?,
        compTaxPalaceID: (json['compTaxPalaceID'] as num?)?.toInt(),
        compMersisNo: json['compMersisNo'] as String?,
        compType: json['compType'] as String?,
        compLogo: json['compLogo'] as String? ?? '',
        createdate: json['createdate'] as String? ?? '',
        documents: ((json['documents'] as List<dynamic>?) ?? const [])
            .map((e) => CompanyDocumentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        partners: ((json['partners'] as List<dynamic>?) ?? const [])
            .map((e) => PartnerItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CompanyDocumentItem {
  final int documentID;
  final int documentTypeID;
  final String documentType;
  final String documentURL;
  final String createDate;

  CompanyDocumentItem({
    required this.documentID,
    required this.documentTypeID,
    required this.documentType,
    required this.documentURL,
    required this.createDate,
  });

  factory CompanyDocumentItem.fromJson(Map<String, dynamic> json) => CompanyDocumentItem(
        documentID: (json['documentID'] as num?)?.toInt() ?? 0,
        documentTypeID: (json['documentTypeID'] as num?)?.toInt() ?? 0,
        documentType: json['documentType'] as String? ?? '',
        documentURL: json['documentURL'] as String? ?? '',
        createDate: json['createDate'] as String? ?? '',
      );
}

class PartnerItem {
  final int partnerID;
  final String partnerName;
  final String partnerTitle;
  final String partnerTaxNo;
  final int partnerTaxPalaceID;
  final String partnerTaxPalace;
  final int partnerCityID;
  final String partnerCity;
  final int partnerDistrictID;
  final String partnerDistrict;
  final String partnerAddress;
  final num partnerShareRatio;
  final num partnerSharePrice;
  final String createDate;
  final List<CompanyDocumentItem> documents;

  PartnerItem({
    required this.partnerID,
    required this.partnerName,
    this.partnerTitle = '',
    this.partnerTaxNo = '',
    this.partnerTaxPalaceID = 0,
    this.partnerTaxPalace = '',
    this.partnerCityID = 0,
    this.partnerCity = '',
    this.partnerDistrictID = 0,
    this.partnerDistrict = '',
    this.partnerAddress = '',
    this.partnerShareRatio = 0,
    this.partnerSharePrice = 0,
    this.createDate = '',
    this.documents = const [],
  });

  factory PartnerItem.fromJson(Map<String, dynamic> json) => PartnerItem(
        partnerID: (json['partnerID'] as num?)?.toInt() ?? 0,
        partnerName: json['partnerName'] as String? ?? '',
        partnerTitle: json['partnerTitle'] as String? ?? '',
        partnerTaxNo: json['partnerTaxNo'] as String? ?? '',
        partnerTaxPalaceID: (json['partnerTaxPalaceID'] as num?)?.toInt() ?? 0,
        partnerTaxPalace: json['partnerTaxPalace'] as String? ?? '',
        partnerCityID: (json['partnerCityID'] as num?)?.toInt() ?? 0,
        partnerCity: json['partnerCity'] as String? ?? '',
        partnerDistrictID: (json['partnerDistrictID'] as num?)?.toInt() ?? 0,
        partnerDistrict: json['partnerDistrict'] as String? ?? '',
        partnerAddress: json['partnerAddress'] as String? ?? '',
        partnerShareRatio: (json['partnerShareRatio'] as num?) ?? 0,
        partnerSharePrice: (json['partnerSharePrice'] as num?) ?? 0,
        createDate: json['createDate'] as String? ?? '',
        documents: ((json['documents'] as List<dynamic>?) ?? const [])
            .map((e) => CompanyDocumentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GetCompaniesResponse {
  final bool error;
  final bool success;
  final List<CompanyItem> companies;
  final String? errorMessage;
  final int? statusCode;

  GetCompaniesResponse({
    required this.error,
    required this.success,
    required this.companies,
    this.errorMessage,
    this.statusCode,
  });

  factory GetCompaniesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['companies'] as List<dynamic>? : null) ?? [];
    return GetCompaniesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      companies: list.map((e) => CompanyItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class AddCompanyRequest {
  final String userToken;
  final String userIdentityNo;
  final String compName;
  final String compTaxNo;
  final int compTaxPalace;
  final String compKepAddress;
  final String compMersisNo;
  final int compType;
  final int compCity;
  final int compDistrict;
  final String compAddress;
  final String compLogo;

  AddCompanyRequest({
    required this.userToken,
    required this.userIdentityNo,
    required this.compName,
    required this.compTaxNo,
    required this.compTaxPalace,
    this.compKepAddress = '',
    this.compMersisNo = '',
    this.compType = 1,
    required this.compCity,
    required this.compDistrict,
    this.compAddress = '',
    this.compLogo = '',
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'userIdentityNo': userIdentityNo,
    'compName': compName,
    'compTaxNo': compTaxNo,
    'compTaxPalace': compTaxPalace,
    'compKepAddress': compKepAddress,
    'compMersisNo': compMersisNo,
    'compType': compType,
    'compCity': compCity,
    'compDistrict': compDistrict,
    'compAddress': compAddress,
    'compLogo': compLogo,
  };
}

class AddCompanyResponse {
  final bool error;
  final bool success;
  final String message;
  final int? compID;
  final String? errorMessage;
  final int? statusCode;

  AddCompanyResponse({
    required this.error,
    required this.success,
    required this.message,
    this.compID,
    this.errorMessage,
    this.statusCode,
  });

  factory AddCompanyResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddCompanyResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      compID: data != null ? (data['compID'] as num?)?.toInt() : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class CompanyTypeItem {
  final int typeID;
  final String typeName;

  CompanyTypeItem({required this.typeID, required this.typeName});

  factory CompanyTypeItem.fromJson(Map<String, dynamic> json) => CompanyTypeItem(
        typeID: (json['typeID'] as num).toInt(),
        typeName: json['typeName'] as String? ?? '',
      );
}

class GetCompanyTypesResponse {
  final bool error;
  final bool success;
  final List<CompanyTypeItem> types;
  final String? errorMessage;
  final int? statusCode;

  GetCompanyTypesResponse({
    required this.error,
    required this.success,
    required this.types,
    this.errorMessage,
    this.statusCode,
  });

  factory GetCompanyTypesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['types'] as List<dynamic>? : null) ?? [];
    return GetCompanyTypesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      types: list.map((e) => CompanyTypeItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class UpdateCompanyRequest {
  final String userToken;
  final String userIdentityNo;
  final int compID;
  final String compName;
  final String compTaxNo;
  final String compTaxPalace;
  final String compKepAddress;
  final String compMersisNo;
  final int compType;
  final int compCity;
  final int compDistrict;
  final String compAddress;
  final String compLogo;

  UpdateCompanyRequest({
    required this.userToken,
    required this.userIdentityNo,
    required this.compID,
    required this.compName,
    required this.compTaxNo,
    required this.compTaxPalace,
    this.compKepAddress = '',
    this.compMersisNo = '',
    this.compType = 1,
    required this.compCity,
    required this.compDistrict,
    this.compAddress = '',
    this.compLogo = '',
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'userIdentityNo': userIdentityNo,
    'compID': compID,
    'compName': compName,
    'compTaxNo': compTaxNo,
    'compTaxPalace': compTaxPalace,
    'compKepAddress': compKepAddress,
    'compMersisNo': compMersisNo,
    'compType': compType,
    'compCity': compCity,
    'compDistrict': compDistrict,
    'compAddress': compAddress,
    'compLogo': compLogo,
  };
}

class DocumentTypeItem {
  final int documentID;
  final String documentName;

  DocumentTypeItem({
    required this.documentID,
    required this.documentName,
  });

  factory DocumentTypeItem.fromJson(Map<String, dynamic> json) {
    return DocumentTypeItem(
      documentID: json['documentID'] as int? ?? 0,
      documentName: json['documentName'] as String? ?? '',
    );
  }
}

class GetDocumentTypesResponse {
  final bool error;
  final bool success;
  final List<DocumentTypeItem> types;
  final String? errorMessage;
  final int? statusCode;

  GetDocumentTypesResponse({
    required this.error,
    required this.success,
    required this.types,
    this.errorMessage,
    this.statusCode,
  });

  factory GetDocumentTypesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final typesList = data?['types'] as List<dynamic>? ?? [];
    
    return GetDocumentTypesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      types: typesList.map((item) => DocumentTypeItem.fromJson(item as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class TaxPalaceItem {
  final int palaceID;
  final String palaceName;

  TaxPalaceItem({
    required this.palaceID,
    required this.palaceName,
  });

  factory TaxPalaceItem.fromJson(Map<String, dynamic> json) => TaxPalaceItem(
        palaceID: (json['palaceID'] as num).toInt(),
        palaceName: json['palaceName'] as String? ?? '',
      );
}

class GetTaxPalacesResponse {
  final bool error;
  final bool success;
  final List<TaxPalaceItem> palaces;
  final String? errorMessage;
  final int? statusCode;

  GetTaxPalacesResponse({
    required this.error,
    required this.success,
    required this.palaces,
    this.errorMessage,
    this.statusCode,
  });

  factory GetTaxPalacesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['palaces'] as List<dynamic>? : null) ?? [];
    return GetTaxPalacesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      palaces: list.map((e) => TaxPalaceItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


class AddPartnerRequest {
  final String userToken;
  final int compID;
  final String partnerFullname;
  final String partnerTitle;
  final String partnerTaxNo;
  final int partnerDistrict;
  final int partnerCity;
  final int partnerTaxPalace;
  final String partnerAddress;
  final String partnerShareRatio;
  final String partnerSharePrice;

  AddPartnerRequest({
    required this.userToken,
    required this.compID,
    required this.partnerFullname,
    this.partnerTitle = '',
    this.partnerTaxNo = '',
    this.partnerDistrict = 0,
    this.partnerCity = 0,
    this.partnerTaxPalace = 0,
    this.partnerAddress = '',
    this.partnerShareRatio = '',
    this.partnerSharePrice = '',
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'compID': compID,
        'partnerFullname': partnerFullname,
        'partnerTitle': partnerTitle,
        'partnerTaxNo': partnerTaxNo,
        'partnerCity': partnerCity,
        'partnerDistrict': partnerDistrict,
        'partnerTaxPalace': partnerTaxPalace,
        'partnerAddress': partnerAddress,
        'partnerShareRatio': partnerShareRatio,
        'partnerSharePrice': partnerSharePrice,
      };
}

class AddPartnerResponse {
  final bool error;
  final bool success;
  final String message;
  final int? partnerID;
  final String? errorMessage;
  final int? statusCode;

  AddPartnerResponse({
    required this.error,
    required this.success,
    required this.message,
    this.partnerID,
    this.errorMessage,
    this.statusCode,
  });

  factory AddPartnerResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddPartnerResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      partnerID: data != null ? (data['partnerID'] as num?)?.toInt() : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class UpdatePartnerRequest {
  final String userToken;
  final int compID;
  final int partnerID;
  final String partnerFullname;
  final String partnerTitle;
  final String partnerTaxNo;
  final int partnerTaxPalace;
  final int partnerCity;
  final int partnerDistrict;
  final String partnerAddress;
  final String partnerShareRatio;
  final String partnerSharePrice;

  UpdatePartnerRequest({
    required this.userToken,
    required this.compID,
    required this.partnerID,
    required this.partnerFullname,
    this.partnerTitle = '',
    this.partnerTaxNo = '',
    this.partnerTaxPalace = 0,
    this.partnerCity = 0,
    this.partnerDistrict = 0,
    this.partnerAddress = '',
    this.partnerShareRatio = '',
    this.partnerSharePrice = '',
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'compID': compID,
        'partnerID': partnerID,
        'partnerFullname': partnerFullname,
        'partnerTitle': partnerTitle,
        'partnerTaxNo': partnerTaxNo,
        'partnerTaxPalace': partnerTaxPalace,
        'partnerCity': partnerCity,
        'partnerDistrict': partnerDistrict,
        'partnerAddress': partnerAddress,
        'partnerShareRatio': partnerShareRatio,
        'partnerSharePrice': partnerSharePrice,
      };
}

class UpdatePartnerResponse {
  final bool error;
  final bool success;
  final String message;
  final String? errorMessage;
  final int? statusCode;

  UpdatePartnerResponse({
    required this.error,
    required this.success,
    required this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdatePartnerResponse.fromJson(Map<String, dynamic> json, int? code) {
    return UpdatePartnerResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


