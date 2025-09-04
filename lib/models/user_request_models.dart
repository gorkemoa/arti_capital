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



