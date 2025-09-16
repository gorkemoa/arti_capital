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
  final String userFirstname;
  final String userLastname;
  final String userEmail;
  final String userBirthday;
  final String userAddress;
  final String userPhone;
  final String userGender;
  final String profilePhoto;

  UpdateUserRequest({
    required this.userToken,
    required this.userFullname,
    required this.userFirstname,
    required this.userLastname,
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
        'userFirstname': userFirstname,
        'userLastname': userLastname,
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


class UpdatePasswordRequest {
  final String userToken;
  final String currentPassword;
  final String password;
  final String passwordAgain;

  UpdatePasswordRequest({
    required this.userToken,
    required this.currentPassword,
    required this.password,
    required this.passwordAgain,
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'currentPassword': currentPassword,
        'password': password,
        'passwordAgain': passwordAgain,
      };
}

class UpdatePasswordResponse {
  final bool error;
  final bool success;
  final String? message; // 200 durumunda "Şifre başarıyla güncellenmiştir."
  final String? errorMessage; // 417 durumunda hata mesajı
  final int? statusCode;

  UpdatePasswordResponse({
    required this.error,
    required this.success,
    this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdatePasswordResponse.fromJson(Map<String, dynamic> json, int? code) {
    return UpdatePasswordResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class UpdateAuthRequest {
  final String userToken;
  UpdateAuthRequest({required this.userToken});
  Map<String, dynamic> toJson() => {
        'userToken': userToken,
      };
}

class UpdateAuthResponse {
  final bool error;
  final bool success;
  final String? message;
  final String? errorMessage;
  final int? statusCode;

  UpdateAuthResponse({
    required this.error,
    required this.success,
    this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory UpdateAuthResponse.fromJson(Map<String, dynamic> json, int? code) {
    return UpdateAuthResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class DeleteUserRequest {
  final String userToken;
  DeleteUserRequest({required this.userToken});
  Map<String, dynamic> toJson() => {
        'userToken': userToken,
      };
}

class DeleteUserResponse {
  final bool error;
  final bool success;
  final String? message;
  final String? errorMessage;
  final int? statusCode;

  DeleteUserResponse({
    required this.error,
    required this.success,
    this.message,
    this.errorMessage,
    this.statusCode,
  });

  factory DeleteUserResponse.fromJson(Map<String, dynamic> json, int? code) {
    return DeleteUserResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class SendContactMessageRequest {
  final String userToken;
  final int subject;
  final String message;

  SendContactMessageRequest({
    required this.userToken,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'userToken': userToken,
        'subject': subject,
        'message': message,
      };
}

class SendContactMessageResponse {
  final bool error;
  final bool success;
  final String? successMessage; // data.success_message
  final int? messageId; // data.message_id
  final String? errorMessage; // 417 durumunda
  final int? statusCode;

  SendContactMessageResponse({
    required this.error,
    required this.success,
    this.successMessage,
    this.messageId,
    this.errorMessage,
    this.statusCode,
  });

  factory SendContactMessageResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    return SendContactMessageResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      successMessage: data != null ? data['success_message'] as String? : null,
      messageId: data != null ? (data['message_id'] as num?)?.toInt() : null,
      errorMessage: json['error_message'] as String?,
      statusCode: code,
    );
  }
}

class ContactSubjectItem {
  final int subjectID;
  final String subjectTitle;

  ContactSubjectItem({required this.subjectID, required this.subjectTitle});

  factory ContactSubjectItem.fromJson(Map<String, dynamic> json) => ContactSubjectItem(
        subjectID: (json['subjectID'] as num).toInt(),
        subjectTitle: json['subjectTitle'] as String? ?? '',
      );
}

class GetContactSubjectsResponse {
  final bool error;
  final bool success;
  final List<ContactSubjectItem> subjects;
  final int? statusCode;

  GetContactSubjectsResponse({
    required this.error,
    required this.success,
    required this.subjects,
    this.statusCode,
  });

  factory GetContactSubjectsResponse.fromJson(Map<String, dynamic> json, int? code) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = (data != null ? data['subjects'] as List<dynamic>? : null) ?? [];
    return GetContactSubjectsResponse(
      error: json['error'] as bool? ?? false,
      success: json['success'] as bool? ?? false,
      subjects: list.map((e) => ContactSubjectItem.fromJson(e as Map<String, dynamic>)).toList(),
      statusCode: code,
    ); 
  }
}

