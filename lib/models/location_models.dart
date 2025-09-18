class CityItem {
  final int cityNo;
  final String cityName;

  const CityItem({required this.cityNo, required this.cityName});

  factory CityItem.fromJson(Map<String, dynamic> json) => CityItem(
        cityNo: (json['cityNo'] as num).toInt(),
        cityName: json['cityName'] as String,
      );
}

class DistrictItem {
  final int districtNo;
  final String districtName;

  const DistrictItem({required this.districtNo, required this.districtName});

  factory DistrictItem.fromJson(Map<String, dynamic> json) => DistrictItem(
        districtNo: (json['districtNo'] as num).toInt(),
        districtName: json['districtName'] as String,
      );
}
