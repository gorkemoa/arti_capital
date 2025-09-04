import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/profile_view.dart';
import 'views/profile_edit_view.dart';
import 'views/settings_view.dart';
import 'views/notifications_view.dart';
import 'package:provider/provider.dart';
import 'viewmodels/login_view_model.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences'ı başlat
  await StorageService.init();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>(create: (_) => LoginViewModel()),
      ],
      child: MaterialApp(
        title: 'Arti Capital',
        theme: AppTheme.light(context),
        home: _getInitialRoute(authService),
        routes: {
          '/login': (context) => const LoginView(),
          '/home': (context) => const HomeView(),
          '/profile': (context) => const ProfileView(),
          '/profile/edit': (context) => const ProfileEditView(),
          '/settings': (context) => const SettingsView(),
          '/notifications': (context) => const NotificationsView(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  Widget _getInitialRoute(AuthService authService) {
    // Kullanıcı giriş yapmış mı kontrol et
    if (authService.isLoggedIn()) {
      return const HomeView();
    } else {
      return const LoginView();
    }
  }
}

