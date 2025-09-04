import 'user_model.dart';

class GetUserRequest {
  final String userToken;
  final String version;
  final String platform;

  GetUserRequest({
    required this.userToken,
    required this.version,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'version': version,
        'platform': platform,
      };
}

class GetUserResponse {
  final bool error;
  final bool success;
  final User? user;
  final String? errorMessage;
  final int? statusCode;

  GetUserResponse({
    required this.error,
    required this.success,
    this.user,
    this.errorMessage,
    this.statusCode,
  });

  factory GetUserResponse.fromJson(Map<String, dynamic> json, int? code) {
    return GetUserResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'] as Map<String, dynamic>)
          : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


class UpdateUserRequest {
  final String userToken;
  final String userFullname;
  final String userEmail;
  final String userBirthday;
  final String userAddress;
  final String userPhone;
  final String userGender;
  final String profilePhoto;

  UpdateUserRequest({
    required this.userToken,
    required this.userFullname,
    required this.userEmail,
    required this.userBirthday,
    required this.userAddress,
    required this.userPhone,
    required this.userGender,
    required this.profilePhoto,
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'userFullname': userFullname,
        'userEmail': userEmail,
        'userBirthday': userBirthday,
        'userAddress': userAddress,
        'userPhone': userPhone,
        'userGender': userGender,
        'profilePhoto': profilePhoto,
      };
}

class UpdateUserResponse {
  final bool error;
  final bool success;
  final String? errorMessage;
  final int? statusCode;

  UpdateUserResponse({
    required this.error,
    required this.success,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdateUserResponse.fromJson(Map<String, dynamic> json, int? code) {
    return UpdateUserResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}


