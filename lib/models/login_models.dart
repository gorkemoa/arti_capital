class LoginRequest {
  final String userName;
  final String password;

  LoginRequest({required this.userName, required this.password});

  Map<String, dynamic> toJson() => {
        'user_name': userName,
        'password': password,
      };
}

class LoginSuccessData {
  final int userId;
  final String token;

  LoginSuccessData({required this.userId, required this.token});

  factory LoginSuccessData.fromJson(Map<String, dynamic> json) =>
      LoginSuccessData(
        userId: json['userID'] as int,
        token: json['token'] as String,
      );
}

class LoginResponse {
  final bool error;
  final bool success;
  final LoginSuccessData? data;
  final String? errorMessage;
  final int? statusCode;

  LoginResponse({
    required this.error,
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json, int? code) {
    return LoginResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? LoginSuccessData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}



