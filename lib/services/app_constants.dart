import 'remote_config_service.dart';

class AppConstants {
  AppConstants._();

  // Base URL'i Remote Config'ten al
  static String get baseUrl => RemoteConfigService.getBaseUrl();

  // Endpoints
  static const String login = '/service/auth/login';
  static const String getUser = '/service/user/id';
  static const String getNotificationsBase = '/service/user/account';
  static const String updateUserBase = '/service/user/update';
  static const String updatePassword = '/service/user/update/password';
  static const String deleteUser = '/service/user/account/delete';
  static const String getMyDocuments = '/service/user/account/myDocuments';
  static const String getAppointments = '/service/user/account/appointments';
  static const String addAppointment = '/service/user/account/appointment/add';
  static const String updateAppointment = '/service/user/account/appointment/update';
  static const String deleteAppointment = '/service/user/account/appointment/delete';
  static const String sendContactMessage = '/service/general/contact/sendMessage';
  static const String getContactSubjects = '/service/general/contact/subjects';
  static const String getAppointmentStatuses = '/service/general/general/appointmentStatuses/all';
  static const String getAppointmentPriorities = '/service/general/general/appointmentPriorities/all';
  static const String getFollowupStatuses = '/service/general/general/followupStatuses/all';
  static const String getFollowupTypes = '/service/general/general/followupTypes/all';
  static const String getPersons = '/service/general/general/persons/all';
  static const String allReadNotifications = '/service/user/account/notification/allRead';
  static const String deleteNotification = '/service/user/account/notification/delete';
  static const String deleteAllNotifications = '/service/user/account/notification/allDelete';
  // 2FA endpoints
  static const String authCodeSend = '/service/auth/code/authSendCode';
  static const String checkCode = '/service/auth/code/checkCode';
  static const String getCompanies = '/service/user/account/companies';
  static const String addCompany = '/service/user/account/company/add';
  static const String updateCompany = '/service/user/account/company/update';
  static const String deleteCompany = '/service/user/account/company/delete';
  static const String addCompanyDocument = '/service/user/account/company/documentAdd';
  static const String updateCompanyDocument = '/service/user/account/company/documentUpdate';
  static const String deleteCompanyDocument = '/service/user/account/company/documentDelete';
  static const String addCompanyAddress = '/service/user/account/company/addressAdd';
  static const String updateCompanyAddress = '/service/user/account/company/addressUpdate';
  static const String deleteCompanyAddress = '/service/user/account/company/addressDelete';

  static const String getAllServices = '/service/general/general/services/all';
  static const String getCities = '/service/general/general/cities/all';
  static const String getCompanyTypes = '/service/general/general/companyTypes/all';
  static const String getDocumentTypesForDocuments = '/service/general/general/documentsTypes/1';
  static const String getDocumentTypesForImages = '/service/general/general/documentsTypes/2';
  static const String getAddressTypes = '/service/general/general/addressTypes/all';
  static const String getBanks = '/service/general/general/banks/all';
  static const String getPasswordTypes = '/service/general/general/passwordTypes/all';
  static String getDistrictsFor(int cityNo) => '/service/general/general/$cityNo/districts';
  static String getTaxPalacesFor(int cityNo) => '/service/general/general/$cityNo/taxPalaces';
  static String getServiceDetail(int id) => '/service/general/general/services/$id';
  // Company detail uses same base with ID path
  static const String addPartner = '/service/user/account/company/partnerAdd';
  static const String updatePartner = '/service/user/account/company/partnerUpdate';
  static const String deletePartner = '/service/user/account/company/partnerDelete';
  static const String addCompanyBank = '/service/user/account/company/bankAdd';
  static const String updateCompanyBank = '/service/user/account/company/bankUpdate';
  static const String deleteCompanyBank = '/service/user/account/company/bankDelete';
  static const String addCompanyPassword = '/service/user/account/company/passwordAdd';
  static const String updateCompanyPassword = '/service/user/account/company/passwordUpdate';
  static const String deleteCompanyPassword = '/service/user/account/company/passwordDelete';
  
  // Project endpoints
  static const String getProjects = '/service/user/account/projects/all';
  static const String addProject = '/service/user/account/projects/add';
  static const String updateProject = '/service/user/account/projects/update';
  static const String deleteProject = '/service/user/account/projects/delete';
  static const String addProjectDocument = '/service/user/account/projects/documentAdd';
  static const String updateProjectDocument = '/service/user/account/projects/documentUpdate';
  static const String deleteProjectDocument = '/service/user/account/projects/documentDelete';
  static const String addTracking = '/service/user/account/projects/trackingAdd';
  static const String updateTracking = '/service/user/account/projects/trackingUpdate';
  static const String deleteTracking = '/service/user/account/projects/trackingDelete';
  static String getProjectDetail(int projectId) => '/service/user/account/projects/$projectId';

  // Dinamik endpoint oluşturucular (userId tabanlı)
  static String getNotificationsFor(int userId) => '$getNotificationsBase/$userId/notifications';
  static String updateUserFor(int userId) => '$updateUserBase/$userId/account';
  static String updateAuthFor(int userId) => '$updateUserBase/$userId/auth';
  static String getCompanyFor(int compId) => '$getNotificationsBase/$compId/company';
  static String getCompanyAddressesFor(int compId) => '/service/user/account/compAddresses/$compId';
  

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
  static String get getMyDocumentsUrl => baseUrl + getMyDocuments;
  static String get getAppointmentsUrl => baseUrl + getAppointments;
  static String get addAppointmentUrl => baseUrl + addAppointment;
  static String get updateAppointmentUrl => baseUrl + updateAppointment;
  static String get deleteAppointmentUrl => baseUrl + deleteAppointment;
}


