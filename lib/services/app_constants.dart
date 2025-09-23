class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://api.office701.com/arti-capital';

  // Endpoints
  static const String login = '/service/auth/login';
  static const String getUser = '/service/user/id';
  static const String getNotificationsBase = '/service/user/account';
  static const String updateUserBase = '/service/user/update';
  static const String updatePassword = '/service/user/update/password';
  static const String deleteUser = '/service/user/account/delete';
  static const String sendContactMessage = '/service/general/contact/sendMessage';
  static const String getContactSubjects = '/service/general/contact/subjects';
  static const String allReadNotifications = '/service/user/account/notification/allRead';
  static const String deleteNotification = '/service/user/account/notification/delete';
  static const String deleteAllNotifications = '/service/user/account/notification/allDelete';
  // 2FA endpoints
  static const String authCodeSend = '/service/auth/code/authSendCode';
  static const String checkCode = '/service/auth/code/checkCode';
  static const String getCompanies = '/service/user/account/companies';
  static const String addCompany = '/service/user/account/company/add';
  static const String updateCompany = '/service/user/account/company/update';
  static const String addCompanyDocument = '/service/user/account/company/documentAdd';
  static const String updateCompanyDocument = '/service/user/account/company/documentUpdate';
  static const String deleteCompanyDocument = '/service/user/account/company/documentDelete';
  static const String addCompanyAddress = '/service/user/account/company/addressAdd';
  static const String updateCompanyAddress = '/service/user/account/company/addressUpdate';
  static const String deleteCompanyAddress = '/service/user/account/company/addressDelete';

  static const String getAllServices = '/service/general/general/services/all';
  static const String getCities = '/service/general/general/cities/all';
  static const String getCompanyTypes = '/service/general/general/companyTypes/all';
  static const String getDocumentTypes = '/service/general/general/documentsTypes/all';
  static const String getAddressTypes = '/service/general/general/addressTypes/all';
  static String getDistrictsFor(int cityNo) => '/service/general/general/$cityNo/districts';
  static String getTaxPalacesFor(int cityNo) => '/service/general/general/$cityNo/taxPalaces';
  static String getServiceDetail(int id) => '/service/general/general/services/$id';
  // Company detail uses same base with ID path
  static const String addPartner = '/service/user/account/company/partnerAdd';
  static const String updatePartner = '/service/user/account/company/partnerUpdate';
  static const String deletePartner = '/service/user/account/company/partnerDelete';

  // Dinamik endpoint oluşturucular (userId tabanlı)
  static String getNotificationsFor(int userId) => '$getNotificationsBase/$userId/notifications';
  static String updateUserFor(int userId) => '$updateUserBase/$userId/account';
  static String updateAuthFor(int userId) => '$updateUserBase/$userId/auth';
  static String getCompanyFor(int compId) => '$getNotificationsBase/$compId/company';
  

  // Basic Auth credentials
  static const String basicUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  static const String basicPassword = 'vRParTCAqTjtmkI17I1EVpPH57Edl0';

  static String get loginUrl => baseUrl + login;
  static String get getUserUrl => baseUrl + getUser;
  static String get updateUserUrl => baseUrl + updateUserBase;
  static String get updatePasswordUrl => baseUrl + updatePassword;
  static String get deleteUserUrl => baseUrl + deleteUser;
  static String get sendContactMessageUrl => baseUrl + sendContactMessage;
  static String get getContactSubjectsUrl => baseUrl + getContactSubjects;
  static String get allReadNotificationsUrl => baseUrl + allReadNotifications;
  static String get deleteNotificationUrl => baseUrl + deleteNotification;
  static String get deleteAllNotificationsUrl => baseUrl + deleteAllNotifications;
  static String get authCodeSendUrl => baseUrl + authCodeSend;
  static String get checkCodeUrl => baseUrl + checkCode;
  static String get getCompaniesUrl => baseUrl + getCompanies;
}


