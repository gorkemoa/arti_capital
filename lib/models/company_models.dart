class CompanyItem {
  final int compID;
  final String compName;
  final String? compTaxNo;
  final int? compTaxPalaceID;
  final String? compTaxPalace;
  final String? compMersisNo;
  final String? compKepAddress;
  final String? compType;
  final String compLogo; // data url veya http url
  final String createdate;
  final String? compEmail;
  final String? compPhone;
  final String? compWebsite;
  final int? compNaceCodeID;
  final List<CompanyAddressItem> addresses;
  final List<CompanyDocumentItem> documents;
  final List<PartnerItem> partners;

  CompanyItem({
    required this.compID,
    required this.compName,
    this.compTaxNo,
    this.compTaxPalaceID,
    this.compTaxPalace,
    this.compMersisNo,
    this.compKepAddress,
    this.compType,
    required this.compLogo,
    required this.createdate,
    this.compEmail,
    this.compPhone,
    this.compWebsite,
    this.compNaceCodeID,
    this.addresses = const [],
    this.documents = const [],
    this.partners = const [],
  });

  // Geriye dönük uyumluluk için birincil adres kısa yolları
  String get compCity => addresses.isNotEmpty ? (addresses.first.addressCity ?? '') : '';
  String get compDistrict => addresses.isNotEmpty ? (addresses.first.addressDistrict ?? '') : '';
  int get compCityID => addresses.isNotEmpty ? (addresses.first.addressCityID ?? 0) : 0;
  int get compDistrictID => addresses.isNotEmpty ? (addresses.first.addressDistrictID ?? 0) : 0;
  String get compAddress => addresses.isNotEmpty ? (addresses.first.addressAddress ?? '') : '';

  factory CompanyItem.fromJson(Map<String, dynamic> json) {
    // Yeni response: fields + addresses/documents/partners
    // Eski response ile uyum için adres alanlarını da kontrol ediyoruz
    final addressesJson = (json['addresses'] as List<dynamic>?) ?? const [];
    final addresses = addressesJson
        .map((e) => CompanyAddressItem.fromJson(e as Map<String, dynamic>))
        .toList();

    // Eski responsedan tekil adres verileri varsa bir AddressItem üretelim
    if (addresses.isEmpty && (
      json.containsKey('compCity') ||
      json.containsKey('compDistrict') ||
      json.containsKey('compAddress')
    )) {
      addresses.add(CompanyAddressItem(
        addressID: 0,
        addressTypeID: null,
        addressType: null,
        addressCityID: (json['compCityID'] as num?)?.toInt(),
        addressCity: json['compCity'] as String?,
        addressDistrictID: (json['compDistrictID'] as num?)?.toInt(),
        addressDistrict: json['compDistrict'] as String?,
        addressAddress: json['compAddress'] as String?,
      ));
    }

    return CompanyItem(
      compID: (json['compID'] as num).toInt(),
      compName: json['compName'] as String? ?? '',
      compTaxNo: json['compTaxNo'] as String?,
      compTaxPalace: json['compTaxPalace'] as String?,
      compTaxPalaceID: (json['compTaxPalaceID'] as num?)?.toInt(),
      compMersisNo: json['compMersisNo'] as String?,
      compKepAddress: json['compKepAddress'] as String?,
      compType: json['compType'] as String?,
      compLogo: json['compLogo'] as String? ?? '',
      createdate: json['createdate'] as String? ?? '',
      compEmail: json['compEmail'] as String?,
      compPhone: json['compPhone'] as String?,
      compWebsite: json['compWebsite'] as String?,
      compNaceCodeID: (json['compNaceCodeID'] as num?)?.toInt(),
      addresses: addresses,
      documents: ((json['documents'] as List<dynamic>?) ?? const [])
          .map((e) => CompanyDocumentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      partners: ((json['partners'] as List<dynamic>?) ?? const [])
          .map((e) => PartnerItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CompanyAddressItem {
  final int addressID;
  final int? addressTypeID;
  final String? addressType;
  final int? addressCityID;
  final String? addressCity;
  final int? addressDistrictID;
  final String? addressDistrict;
  final String? addressAddress;

  CompanyAddressItem({
    required this.addressID,
    this.addressTypeID,
    this.addressType,
    this.addressCityID,
    this.addressCity,
    this.addressDistrictID,
    this.addressDistrict,
    this.addressAddress,
  });

  factory CompanyAddressItem.fromJson(Map<String, dynamic> json) => CompanyAddressItem(
        addressID: (json['addressID'] as num?)?.toInt() ?? 0,
        addressTypeID: (json['addressTypeID'] as num?)?.toInt(),
        addressType: json['addressType'] as String?,
        addressCityID: (json['addressCityID'] as num?)?.toInt(),
        addressCity: json['addressCity'] as String?,
        addressDistrictID: (json['addressDistrictID'] as num?)?.toInt(),
        addressDistrict: json['addressDistrict'] as String?,
        addressAddress: json['addressAddress'] as String?,
      );
}

class AddCompanyAddressRequest {
  final String userToken;
  final int compID;
  final int addressType;
  final int addressCity;
  final int addressDistrict;
  final String addressAddress;

  AddCompanyAddressRequest({
    required this.userToken,
    required this.compID,
    required this.addressType,
    required this.addressCity,
    required this.addressDistrict,
    this.addressAddress = '',
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'compID': compID,
        'addressType': addressType,
        'addressCity': addressCity,
        'addressDistrict': addressDistrict,
        'addressAddress': addressAddress,
      };
}

class AddCompanyAddressResponse {
  final bool error;
  final bool success;
  final String message;
  final int? addressID;
  final String? errorMessage;
  final int? statusCode;

  AddCompanyAddressResponse({
    required this.error,
    required this.success,
    required this.message,
    this.addressID,
    this.errorMessage,
    this.statusCode,
  });

  factory AddCompanyAddressResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddCompanyAddressResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      addressID: data != null ? (data['addressID'] as num?)?.toInt() : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class UpdateCompanyAddressRequest {
  final String userToken;
  final int compID;
  final int addressID;
  final int addressType;
  final int addressCity;
  final int addressDistrict;
  final String addressAddress;

  UpdateCompanyAddressRequest({
    required this.userToken,
    required this.compID,
    required this.addressID,
    required this.addressType,
    required this.addressCity,
    required this.addressDistrict,
    required this.addressAddress,
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'compID': compID,
        'addressID': addressID,
        'addressType': addressType,
        'addressCity': addressCity,
        'addressDistrict': addressDistrict,
        'addressAddress': addressAddress,
      };
}

class UpdateCompanyAddressResponse {
  final bool error;
  final bool success;
  final String message;
  final int? addressID;
  final String? errorMessage;
  final int? statusCode;

  UpdateCompanyAddressResponse({
    required this.error,
    required this.success,
    required this.message,
    this.addressID,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdateCompanyAddressResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return UpdateCompanyAddressResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      addressID: data != null ? (data['addressID'] as num?)?.toInt() : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
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

  factory CompanyDocumentItem.fromJson(Map<String, dynamic> json) {
    int resolveInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    final id = json.containsKey('documentID')
        ? resolveInt(json['documentID'])
        : json.containsKey('id')
            ? resolveInt(json['id'])
            : json.containsKey('docID')
                ? resolveInt(json['docID'])
                : json.containsKey('partnerDocumentID')
                    ? resolveInt(json['partnerDocumentID'])
                    : 0;

    final typeId = json.containsKey('documentTypeID')
        ? resolveInt(json['documentTypeID'])
        : json.containsKey('typeID')
            ? resolveInt(json['typeID'])
            : 0;

    final typeName = (json['documentType'] as String?) ?? (json['typeName'] as String?) ?? '';
    final url = (json['documentURL'] as String?) ?? (json['documentUrl'] as String?) ?? (json['url'] as String?) ?? '';
    final created = (json['createDate'] as String?) ?? (json['createdAt'] as String?) ?? '';

    return CompanyDocumentItem(
      documentID: id,
      documentTypeID: typeId,
      documentType: typeName,
      documentURL: url,
      createDate: created,
    );
  }
}

class PartnerItem {
  final int partnerID;
  final String partnerName;
  final String partnerFirstname;
  final String partnerLastname;
  final String partnerFullname;
  final String partnerIdentityNo;
  final String partnerBirthday;
  final String partnerTitle;
  final String partnerTaxNo;
  final int partnerTaxPalaceID;
  final String partnerTaxPalace;
  final int partnerCityID;
  final String partnerCity;
  final int partnerDistrictID;
  final String partnerDistrict;
  final String partnerAddress;
  final String partnerShareRatio;
  final String partnerSharePrice;
  final String createDate;
  final List<CompanyDocumentItem> documents;

  PartnerItem({
    required this.partnerID,
    required this.partnerName,
    this.partnerFirstname = '',
    this.partnerLastname = '',
    this.partnerFullname = '',
    this.partnerIdentityNo = '',
    this.partnerBirthday = '',
    this.partnerTitle = '',
    this.partnerTaxNo = '',
    this.partnerTaxPalaceID = 0,
    this.partnerTaxPalace = '',
    this.partnerCityID = 0,
    this.partnerCity = '',
    this.partnerDistrictID = 0,
    this.partnerDistrict = '',
    this.partnerAddress = '',
    this.partnerShareRatio = '',
    this.partnerSharePrice = '',
    this.createDate = '',
    this.documents = const [],
  });

  factory PartnerItem.fromJson(Map<String, dynamic> json) => PartnerItem(
        partnerID: (json['partnerID'] as num?)?.toInt() ?? 0,
        partnerName: (json['partnerName'] as String?)
                ?? (json['partnerFullname'] as String?)
                ?? '',
        partnerFirstname: json['partnerFirstname'] as String? ?? '',
        partnerLastname: json['partnerLastname'] as String? ?? '',
        partnerFullname: json['partnerFullname'] as String? ?? '',
        partnerIdentityNo: json['partnerIdentityNo'] as String? ?? '',
        partnerBirthday: json['partnerBirthday'] as String? ?? '',
        partnerTitle: json['partnerTitle'] as String? ?? '',
        partnerTaxNo: json['partnerTaxNo'] as String? ?? '',
        partnerTaxPalaceID: (json['partnerTaxPalaceID'] as num?)?.toInt() ?? 0,
        partnerTaxPalace: json['partnerTaxPalace'] as String? ?? '',
        partnerCityID: (json['partnerCityID'] as num?)?.toInt() ?? 0,
        partnerCity: json['partnerCity'] as String? ?? '',
        partnerDistrictID: (json['partnerDistrictID'] as num?)?.toInt() ?? 0,
        partnerDistrict: json['partnerDistrict'] as String? ?? '',
        partnerAddress: json['partnerAddress'] as String? ?? '',
        partnerShareRatio: (json['partnerShareRatio'] as String?) ?? '',
        partnerSharePrice: (json['partnerSharePrice'] as String?) ?? '',
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
  final String compEmail;
  final String compPhone;
  final String compWebsite;
  final String compTaxNo;
  final int compTaxPalace;
  final String compKepAddress;
  final String compMersisNo;
  final String compNaceCode;
  final String ncID;
  final int compType;
  final int compCity;
  final int compDistrict;
  final String compAddress;
  final int compAddressType;
  final String compLogo;

  AddCompanyRequest({
    required this.userToken,
    required this.userIdentityNo,
    required this.compName,
    this.compEmail = '',
    this.compPhone = '',
    this.compWebsite = '',
    required this.compTaxNo,
    required this.compTaxPalace,
    this.compKepAddress = '',
    this.compMersisNo = '',
    this.compNaceCode = '',
    this.ncID = '',
    this.compType = 1,
    required this.compCity,
    required this.compDistrict,
    this.compAddress = '',
    this.compAddressType = 1,
    this.compLogo = '',
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'userIdentityNo': userIdentityNo,
    'compName': compName,
    'compEmail': compEmail,
    'compPhone': compPhone,
    'compWebsite': compWebsite,
    'compTaxNo': compTaxNo,
    'compTaxPalace': compTaxPalace,
    'compKepAddress': compKepAddress,
    'compMersisNo': compMersisNo,
    'compNaceCode': compNaceCode,
    'ncID': ncID,
    'compType': compType,
    'compCity': compCity,
    'compDistrict': compDistrict,
    'compAddress': compAddress,
    'compAddressType': compAddressType,
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

class AddressTypeItem {
  final int typeID;
  final String typeName;

  AddressTypeItem({required this.typeID, required this.typeName});

  factory AddressTypeItem.fromJson(Map<String, dynamic> json) => AddressTypeItem(
        typeID: (json['typeID'] as num).toInt(),
        typeName: json['typeName'] as String? ?? '',
      );
}

class NaceCodeItem {
  final String ncID;
  final String sectorCode;
  final String professionCode;
  final String naceCode;
  final String naceDesc;
  final String sectorDesc;
  final String professionDesc;

  NaceCodeItem({
    required this.ncID,
    required this.sectorCode,
    required this.professionCode,
    required this.naceCode,
    required this.naceDesc,
    required this.sectorDesc,
    required this.professionDesc,
  });

  factory NaceCodeItem.fromJson(Map<String, dynamic> json) => NaceCodeItem(
        ncID: json['ncID'] as String? ?? '',
        sectorCode: json['sectorCode'] as String? ?? '',
        professionCode: json['professionCode'] as String? ?? '',
        naceCode: json['naceCode'] as String? ?? '',
        naceDesc: json['naceDesc'] as String? ?? '',
        sectorDesc: json['sectorDesc'] as String? ?? '',
        professionDesc: json['professionDesc'] as String? ?? '',
      );
}

class GetAddressTypesResponse {
  final bool error;
  final bool success;
  final List<AddressTypeItem> types;
  final String? errorMessage;
  final int? statusCode;

  GetAddressTypesResponse({
    required this.error,
    required this.success,
    required this.types,
    this.errorMessage,
    this.statusCode,
  });

  factory GetAddressTypesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['types'] as List<dynamic>? : null) ?? [];
    return GetAddressTypesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      types: list.map((e) => AddressTypeItem.fromJson(e as Map<String, dynamic>)).toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
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
  final String compEmail;
  final String compPhone;
  final String compWebsite;
  final String compTaxNo;
  final int compTaxPalace;
  final String compKepAddress;
  final String compMersisNo;
  final String compNaceCode;
  final String ncID;
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
    this.compEmail = '',
    this.compPhone = '',
    this.compWebsite = '',
    required this.compTaxNo,
    required this.compTaxPalace,
    this.compKepAddress = '',
    this.compMersisNo = '',
    this.compNaceCode = '',
    this.ncID = '',
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
    'compEmail': compEmail,
    'compPhone': compPhone,
    'compWebsite': compWebsite,
    'compTaxNo': compTaxNo,
    'compTaxPalace': compTaxPalace,
    'compKepAddress': compKepAddress,
    'compMersisNo': compMersisNo,
    'compNaceCode': compNaceCode,
    'ncID': ncID,
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
  final String partnerFirstname;
  final String partnerLastname;
  final String partnerIdentityNo;
  final String partnerBirthday;
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
    this.partnerFirstname = '',
    this.partnerLastname = '',
    this.partnerIdentityNo = '',
    this.partnerBirthday = '',
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
        'partnerFirstname': partnerFirstname,
        'partnerLastname': partnerLastname,
        'partnerIdentityNo': partnerIdentityNo,
        'partnerBirthday': partnerBirthday,
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
  final String partnerFirstname;
  final String partnerLastname;
  final String partnerIdentityNo;
  final String partnerBirthday;
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
    this.partnerFirstname = '',
    this.partnerLastname = '',
    this.partnerIdentityNo = '',
    this.partnerBirthday = '',
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
        'partnerFirstname': partnerFirstname,
        'partnerLastname': partnerLastname,
        'partnerIdentityNo': partnerIdentityNo,
        'partnerBirthday': partnerBirthday,
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


