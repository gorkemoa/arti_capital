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
  final String? compDesc;
  final String? compEmail;
  final String? compPhone;
  final String? compWebsite;
  final int? compNaceCodeID;
  final List<CompanyAddressItem> addresses;
  final List<CompanyDocumentItem> documents;
  final List<PartnerItem> partners;
  final List<CompanyBankItem> banks;
  final List<CompanyPasswordItem> passwords;
  final List<CompanyImageItem> images;

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
    this.compDesc,
    this.compEmail,
    this.compPhone,
    this.compWebsite,
    this.compNaceCodeID,
    this.addresses = const [],
    this.documents = const [],
    this.partners = const [],
    this.banks = const [],
    this.passwords = const [],
    this.images = const [],
  });

  // Geriye dönük uyumluluk için birincil adres kısa yolları
  String get compCity => addresses.isNotEmpty ? (addresses.first.addressCity ?? '') : '';
  String get compDistrict => addresses.isNotEmpty ? (addresses.first.addressDistrict ?? '') : '';
  int get compCityID => addresses.isNotEmpty ? (addresses.first.addressCityID ?? 0) : 0;
  int get compDistrictID => addresses.isNotEmpty ? (addresses.first.addressDistrictID ?? 0) : 0;
  String get compAddress => addresses.isNotEmpty ? (addresses.first.addressAddress ?? '') : '';

  factory CompanyItem.fromJson(Map<String, dynamic> json) {
 
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
      compDesc: json['compDesc'] as String?,
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
      banks: ((json['banks'] as List<dynamic>?) ?? const [])
          .map((e) => CompanyBankItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      passwords: ((json['passwords'] as List<dynamic>?) ?? const [])
          .map((e) => CompanyPasswordItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: ((json['images'] as List<dynamic>?) ?? const [])
          .map((e) => CompanyImageItem.fromJson(e as Map<String, dynamic>))
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

class CompanyPasswordItem {
  final int passwordID;
  final int passwordTypeID;
  final String passwordType;
  final String passwordUsername;
  final String passwordPassword;
  final String createDate;

  CompanyPasswordItem({
    required this.passwordID,
    required this.passwordTypeID,
    required this.passwordType,
    required this.passwordUsername,
    required this.passwordPassword,
    required this.createDate,
  });

  factory CompanyPasswordItem.fromJson(Map<String, dynamic> json) {
    return CompanyPasswordItem(
      passwordID: (json['passwordID'] as num?)?.toInt() ?? 0,
      passwordTypeID: (json['passwordTypeID'] as num?)?.toInt() ?? 0,
      passwordType: json['passwordType'] as String? ?? '',
      passwordUsername: json['passwordUsername'] as String? ?? '',
      passwordPassword: json['passwordPassword'] as String? ?? '',
      createDate: json['createDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'passwordID': passwordID,
    'passwordTypeID': passwordTypeID,
    'passwordType': passwordType,
    'passwordUsername': passwordUsername,
    'passwordPassword': passwordPassword,
    'createDate': createDate,
  };
}

class AddCompanyPasswordRequest {
  final String userToken;
  final int compID;
  final int passType;
  final String passUsername;
  final String passPassword;

  AddCompanyPasswordRequest({
    required this.userToken,
    required this.compID,
    required this.passType,
    required this.passUsername,
    required this.passPassword,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'compID': compID,
    'passType': passType,
    'passUsername': passUsername,
    'passPassword': passPassword,
  };
}

class AddCompanyPasswordResponse {
  final bool error;
  final bool success;
  final String message;
  final int? passwordID;
  final String? errorMessage;
  final int? statusCode;

  AddCompanyPasswordResponse({
    required this.error,
    required this.success,
    required this.message,
    this.passwordID,
    this.errorMessage,
    this.statusCode,
  });

  factory AddCompanyPasswordResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddCompanyPasswordResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      passwordID: data?['passwordID'] as int?,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class UpdateCompanyPasswordRequest {
  final String userToken;
  final int compID;
  final int passID;
  final int passType;
  final String passUsername;
  final String passPassword;

  UpdateCompanyPasswordRequest({
    required this.userToken,
    required this.compID,
    required this.passID,
    required this.passType,
    required this.passUsername,
    required this.passPassword,
  });

  Map<String, dynamic> toJson() => {
    'userToken': userToken,
    'compID': compID,
    'passID': passID,
    'passType': passType,
    'passUsername': passUsername,
    'passPassword': passPassword,
  };
}

class UpdateCompanyPasswordResponse {
  final bool error;
  final bool success;
  final String message;
  final String? errorMessage;
  final int? statusCode;

  UpdateCompanyPasswordResponse({
    required this.error,
    required this.success,
    required this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdateCompanyPasswordResponse.fromJson(Map<String, dynamic> json, int? code) {
    return UpdateCompanyPasswordResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class CompanyImageItem {
  final int imageID;
  final int imageTypeID;
  final String imageType;
  final String imageURL;
  final String createDate;

  CompanyImageItem({
    required this.imageID,
    required this.imageTypeID,
    required this.imageType,
    required this.imageURL,
    required this.createDate,
  });

  factory CompanyImageItem.fromJson(Map<String, dynamic> json) {
    return CompanyImageItem(
      imageID: (json['imageID'] as num?)?.toInt() ?? 0,
      imageTypeID: (json['imageTypeID'] as num?)?.toInt() ?? 0,
      imageType: json['imageType'] as String? ?? '',
      imageURL: json['imageURL'] as String? ?? '',
      createDate: json['createDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'imageID': imageID,
    'imageTypeID': imageTypeID,
    'imageType': imageType,
    'imageURL': imageURL,
    'createDate': createDate,
  };
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

class PasswordTypeItem {
  final int typeID;
  final String typeName;

  PasswordTypeItem({
    required this.typeID,
    required this.typeName,
  });

  factory PasswordTypeItem.fromJson(Map<String, dynamic> json) {
    return PasswordTypeItem(
      typeID: json['typeID'] as int? ?? 0,
      typeName: json['typeName'] as String? ?? '',
    );
  }
}

class GetPasswordTypesResponse {
  final bool error;
  final bool success;
  final List<PasswordTypeItem> types;
  final String? errorMessage;
  final int? statusCode;

  GetPasswordTypesResponse({
    required this.error,
    required this.success,
    required this.types,
    this.errorMessage,
    this.statusCode,
  });

  factory GetPasswordTypesResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final typesList = data?['types'] as List<dynamic>? ?? [];
    
    return GetPasswordTypesResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      types: typesList.map((item) => PasswordTypeItem.fromJson(item as Map<String, dynamic>)).toList(),
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

// Bank related models
class CompanyBankItem {
  final int cbID;
  final int compID;
  final int bankID;
  final String bankName;
  final String bankUsername;
  final String bankBranch;
  final String bankBranchCode;
  final String bankIBAN;
  final String? bankLogo;

  CompanyBankItem({
    required this.cbID,
    required this.compID,
    required this.bankID,
    required this.bankName,
    required this.bankUsername,
    required this.bankBranch,
    required this.bankBranchCode,
    required this.bankIBAN,
    this.bankLogo,
  });

  factory CompanyBankItem.fromJson(Map<String, dynamic> json) {
    return CompanyBankItem(
      cbID: json['cbID'] as int? ?? 0,
      compID: json['compID'] as int? ?? 0,
      bankID: json['bankID'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankUsername: json['bankUsername'] as String? ?? '',
      bankBranch: json['bankBranch'] as String? ?? '',
      bankBranchCode: json['bankBranchCode'] as String? ?? '',
      bankIBAN: json['bankIBAN'] as String? ?? '',
      bankLogo: json['bankLogo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cbID': cbID,
      'compID': compID,
      'bankID': bankID,
      'bankName': bankName,
      'bankUsername': bankUsername,
      'bankBranch': bankBranch,
      'bankBranchCode': bankBranchCode,
      'bankIBAN': bankIBAN,
      if (bankLogo != null) 'bankLogo': bankLogo,
    };
  }
}

class AddCompanyBankRequest {
  final String userToken;
  final int compID;
  final int bankID;
  final String bankUsername;
  final String bankBranchName;
  final String bankBranchCode;
  final String compIban;

  AddCompanyBankRequest({
    required this.userToken,
    required this.compID,
    required this.bankID,
    required this.bankUsername,
    required this.bankBranchName,
    required this.bankBranchCode,
    required this.compIban,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'bankID': bankID,
      'bankUsername': bankUsername,
      'bankBranchName': bankBranchName,
      'bankBranchCode': bankBranchCode,
      'compIban': compIban,
    };
  }
}

class AddCompanyBankResponse {
  final bool error;
  final bool success;
  final String message;
  final int? cbID;
  final String? errorMessage;
  final int? statusCode;

  AddCompanyBankResponse({
    required this.error,
    required this.success,
    required this.message,
    this.cbID,
    this.errorMessage,
    this.statusCode,
  });

  factory AddCompanyBankResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return AddCompanyBankResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      cbID: data?['cbID'] as int?,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

// Bank lookup models
class BankItem {
  final int bankID;
  final String bankName;
  final String bankLogo;

  BankItem({
    required this.bankID,
    required this.bankName,
    required this.bankLogo,
  });

  factory BankItem.fromJson(Map<String, dynamic> json) {
    return BankItem(
      bankID: json['bankID'] as int? ?? 0,
      bankName: json['bankName'] as String? ?? '',
      bankLogo: json['bankLogo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankID': bankID,
      'bankName': bankName,
      'bankLogo': bankLogo,
    };
  }
}

class GetBanksResponse {
  final bool error;
  final bool success;
  final List<BankItem> banks;
  final String? errorMessage;
  final int? statusCode;

  GetBanksResponse({
    required this.error,
    required this.success,
    required this.banks,
    this.errorMessage,
    this.statusCode,
  });

  factory GetBanksResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final banksJson = data?['banks'] as List<dynamic>? ?? [];
    
    return GetBanksResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      banks: banksJson
          .map((e) => BankItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


