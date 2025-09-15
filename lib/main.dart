import 'package:arti_capital/views/panel_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/profile_view.dart';
import 'views/profile_edit_view.dart';
import 'views/settings_view.dart';
import 'views/notifications_view.dart';
import 'views/requests_view.dart';
import 'views/support_view.dart';
import 'views/support_detail_view.dart';
import 'widgets/app_bottom_nav.dart';
import 'package:provider/provider.dart';
import 'viewmodels/login_view_model.dart';
import 'viewmodels/home_view_model.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/notifications_service.dart';
import 'services/api_client.dart';
import 'firebase_options.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'dart:convert';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'services/app_group_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences'ı başlat
  await StorageService.init();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // FCM servislerini başlat
  await NotificationsService.initialize();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // API interceptors: uygulama başında kur
  ApiClient.initInterceptors();
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
        ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
      ],
      child: MaterialApp(
        title: 'Arti Capital',
        theme: AppTheme.light(context),
        navigatorKey: ApiClient.navigatorKey,
        home: _ShareIntentGate(initial: _getInitialRoute(authService)),
        routes: {
          '/login': (context) => const LoginView(),
          '/home': (context) => const _MainNavigation(),
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
      return const _MainNavigation();
    } else {
      return const LoginView();
    }
  }
}

class _ShareIntentGate extends StatefulWidget {
  const _ShareIntentGate({required this.initial});
  final Widget initial;

  @override
  State<_ShareIntentGate> createState() => _ShareIntentGateState();
}

class _ShareIntentGateState extends State<_ShareIntentGate> {
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSub;
  bool _checkedInitial = false;
  bool _handledShare = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeHandleSharePayload();
    });
  }
  Future<void> _maybeHandleSharePayload() async {
    if (_handledShare) {
      setState(() { _checkedInitial = true; });
      return;
    }
    final payload = await AppGroupService.readSharePayload();
    setState(() { _checkedInitial = true; });
    if (!mounted) return;
    if (payload == null) return;

    final String? mode = payload['mode'] as String?; // 'project' | 'message'
    final String? folder = payload['folder'] as String?; // Proje türü
    final String? text = payload['text'] as String?; // not (ileride gösterim için saklı)

    // Proje modundaysa SupportDetailView'a yönlendir
    if (mode == 'project') {
      // Support kategorileri içinden eşleştir; yoksa 'Tümü'
      final String category = (folder != null && kSupportCategories.contains(folder)) ? folder : 'Tümü';
      _handledShare = true;
      await AppGroupService.clearSharePayload();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupportDetailView(title: category),
          settings: const RouteSettings(name: '/support/detail-from-share'),
        ),
      );

      // İsteğe bağlı: notu clipboard'a al veya snack olarak gösterilebilir
      return;
    }
  }


 

  @override
  void dispose() {
    _mediaStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedInitial) {
      return const Scaffold(body: SizedBox());
    }
    return widget.initial;
  }
}

class _MainNavigation extends StatefulWidget {
  const _MainNavigation();

  @override
  State<_MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<_MainNavigation> {
  String _userName = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Önce localden dene (hızlı görüntüleme)
    final cached = StorageService.getUserData();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        final user = User.fromJson(map);
        _userName = (user.userFullname.isNotEmpty ? user.userFullname : user.userName).trim();
        if (_userName.isNotEmpty) {
          await AppGroupService.setLoggedInUserName(_userName);
        }
      } catch (_) {}
    }

    setState(() { _loaded = true; });

    // Ardından API'den güncelle
    try {
      final resp = await UserService().getUser();
      if (mounted && resp.success && resp.user != null) {
        final user = resp.user!;
        final freshName = (user.userFullname.isNotEmpty ? user.userFullname : user.userName).trim();
        if (freshName.isNotEmpty) {
          setState(() { _userName = freshName; });
          await AppGroupService.setLoggedInUserName(freshName);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: SizedBox());
    }
    
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, child) {
        final currentIndex = homeViewModel.currentIndex;
        
        Widget getCurrentPage() {
          switch (currentIndex) {
            case 0:
              return PanelView(userName: _userName);
            case 1:
              return const RequestsView();
            case 2:
              return const SupportView();
            case 3:
              return const ProfileView();
            default:
              return PanelView(userName: _userName);
          }
        }

        return Scaffold(
          body: getCurrentPage(),
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTap: homeViewModel.setCurrentIndex,
          ),
        );
      },
    );
  }
}

