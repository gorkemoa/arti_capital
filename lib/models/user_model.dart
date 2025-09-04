class User {
  final int userID;
  final String userName;
  final String userFirstname;
  final String userLastname;
  final String userFullname;
  final String userEmail;
  final String userPhone;
  final String userRank;
  final String userGender;
  final String userToken;
  final String platform;
  final String userVersion;
  final String iOSVersion;
  final String androidVersion;
  final String profilePhoto;

  User({
    required this.userID,
    required this.userName,
    required this.userFirstname,
    required this.userLastname,
    required this.userFullname,
    required this.userEmail,
    required this.userPhone,
    required this.userRank,
    required this.userGender,
    required this.userToken,
    required this.platform,
    required this.userVersion,
    required this.iOSVersion,
    required this.androidVersion,
    required this.profilePhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userID: json['userID'] as int,
        userName: json['userName'] as String,
        userFirstname: json['userFirstname'] as String,
        userLastname: json['userLastname'] as String,
        userFullname: json['userFullname'] as String,
        userEmail: json['userEmail'] as String,
        userPhone: json['userPhone'] as String,
        userRank: json['userRank'] as String,
        userGender: json['userGender'] as String,
        userToken: json['userToken'] as String,
        platform: json['platform'] as String,
        userVersion: json['userVersion'] as String,
        iOSVersion: json['iOSVersion'] as String,
        androidVersion: json['androidVersion'] as String,
        profilePhoto: json['profilePhoto'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'userName': userName,
        'userFirstname': userFirstname,
        'userLastname': userLastname,
        'userFullname': userFullname,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'userRank': userRank,
        'userGender': userGender,
        'userToken': userToken,
        'platform': platform,
        'userVersion': userVersion,
        'iOSVersion': iOSVersion,
        'androidVersion': androidVersion,
        'profilePhoto': profilePhoto,
      };
}



