class AuthCodeSendRequest {
  final String userToken;
  final int sendType; // 1 - SMS, 2 - E-Posta

  AuthCodeSendRequest({required this.userToken, required this.sendType});

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'sendType': sendType,
      };
}

class AuthCodeSendData {
  final String codeToken;

  AuthCodeSendData({required this.codeToken});

  factory AuthCodeSendData.fromJson(Map<String, dynamic> json) =>
      AuthCodeSendData(codeToken: json['codeToken'] as String);
}

class AuthCodeSendResponse {
  final bool error;
  final bool success;
  final String? message;
  final AuthCodeSendData? data;
  final int? statusCode;
  final String? errorMessage;

  AuthCodeSendResponse({
    required this.error,
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errorMessage,
  });

  factory AuthCodeSendResponse.fromJson(Map<String, dynamic> json, int? code) {
    return AuthCodeSendResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? (json['success_message'] as String?),
      data: json['data'] != null
          ? AuthCodeSendData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      statusCode: code,
      errorMessage: json['error_message'] as String?,
    );
  }
}

class CheckCodeRequest {
  final String code;
  final String codeToken;

  CheckCodeRequest({required this.code, required this.codeToken});

  Map<String, dynamic> toJson() => {
        'code': code,
        'codeToken': codeToken,
      };
}

class CheckCodeData {
  final String passToken;

  CheckCodeData({required this.passToken});

  factory CheckCodeData.fromJson(Map<String, dynamic> json) =>
      CheckCodeData(passToken: (json['passToken'] as String?) ?? '');
}

class CheckCodeResponse {
  final bool error;
  final bool success;
  final String? message;
  final CheckCodeData? data;
  final int? statusCode;
  final String? errorMessage;

  CheckCodeResponse({
    required this.error,
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errorMessage,
  });

  factory CheckCodeResponse.fromJson(Map<String, dynamic> json, int? code) {
    return CheckCodeResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: (json['message'] as String?) ?? (json['success_message'] as String?),
      data: json['data'] != null
          ? CheckCodeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      statusCode: code,
      errorMessage: json['error_message'] as String?,
    );
  }
}





