class AppConstants {
  AppConstants._();

  // Base URL (gerekirse debug/release farklılaştırılabilir)
  static const String baseUrl = 'https://api.office701.com/arti-capital';

  // Endpoints
  static const String login = '/service/auth/login';
  static const String getUser = '/service/user/id';
  static const String getNotifications = '/service/user/account/3/natifications';

  // Basic Auth credentials
  static const String basicUsername = 'Tr1VAhW2ICWHJN2nlvp9K5ycGoyMJM';
  static const String basicPassword = 'vRParTCAqTjtmkI17I1EVpPH57Edl0';

  static String get loginUrl => baseUrl + login;
  static String get getUserUrl => baseUrl + getUser;
  static String get getNotificationsUrl => baseUrl + getNotifications;
}


