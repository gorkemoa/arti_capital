class CompanyItem {
  final int compID;
  final String compName;
  final String compCity;
  final String compDistrict;
  final int compCityID;
  final int compDistrictID;
  final String compAddress;
  final String compLogo; // data url veya http url
  final String createdate;

  CompanyItem({
    required this.compID,
    required this.compName,
    required this.compCity,
    required this.compDistrict,
    required this.compCityID,
    required this.compDistrictID,
    required this.compAddress,
    required this.compLogo,
    required this.createdate,
  });

  factory CompanyItem.fromJson(Map<String, dynamic> json) => CompanyItem(
        compID: (json['compID'] as num).toInt(),
        compName: json['compName'] as String? ?? '',
        compCity: json['compCity'] as String? ?? '',
        compDistrict: json['compDistrict'] as String? ?? '',
        compCityID: (json['compCityID'] as num?)?.toInt() ?? 0,
        compDistrictID: (json['compDistrictID'] as num?)?.toInt() ?? 0,
        compAddress: json['compAddress'] as String? ?? '',
        compLogo: json['compLogo'] as String? ?? '',
        createdate: json['createdate'] as String? ?? '',
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


