import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'core/theme/soul_flow_theme.dart';
import 'core/services/localizations.dart';
import 'core/services/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/presentation/views/onboarding_screen.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/mood/presentation/views/soul_flow_home_frame.dart';

// Diem khoi dau cua toan bo ung dung Flutter (Entry point)
void main() async {
  // Dam bao cac thanh phan bindings cua Flutter duoc khoi tao truoc khi dung async
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khoi tao Firebase cho ung dung
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // 2. Khoi tao dich vu thong bao nhac nho hang ngay
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    
    // Lay thong tin lua chon nhac nho tu bo nho tam thoi SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('daily_notification_enabled') ?? true;
    
    // Neu nguoi dung dong y nhan thong bao thi yeu cau quyen va len lich thong bao
    if (notificationsEnabled) {
      await notificationService.requestPermissions();
      await notificationService.scheduleDailyReminder();
    }
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  // 3. Xac dinh man hinh dau tien khi nguoi dung mo app (Initial Route)
  Widget initialScreen;
  try {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (!seenOnboarding) {
      // Neu chua tung xem man hinh gioi thieu -> Mo OnboardingScreen
      initialScreen = const OnboardingScreen();
    } else if (!isLoggedIn) {
      // Neu chua dang nhap -> Mo LoginScreen
      initialScreen = const LoginScreen();
    } else {
      // Neu da dang nhap truoc do -> Mo trang chu chinh (SoulFlowHomeFrame)
      initialScreen = const SoulFlowHomeFrame();
    }
  } catch (e) {
    initialScreen = const OnboardingScreen();
  }

  // Run app kem theo MultiProvider de quan ly trang thai app (Theme, Ngon ngu, User)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Quan ly theme (Sang/Toi)
        ChangeNotifierProvider(create: (_) => LocaleProvider()), // Quan ly ngon ngu (Anh/Viet)
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Quan ly dang nhap, dang ky
      ],
      child: SoulFlowApp(initialScreen: initialScreen),
    ),
  );
}

// Widget chinh chua cau hinh MaterialApp
class SoulFlowApp extends StatelessWidget {
  final Widget initialScreen;
  const SoulFlowApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      // Key dieu huong thong bao de nhan vao thong bao co the tu dong mo man hinh mong muon
      navigatorKey: NotificationService.navigatorKey,
      title: 'SoulFlow',
      theme: SoulFlowTheme.lightTheme, // Theme sang
      darkTheme: SoulFlowTheme.darkTheme, // Theme toi
      themeMode: themeProvider.themeMode, // Che do hien tai (Light/Dark/System)
      locale: localeProvider.locale, // Ngon ngu hien tai
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(), // Localization tu dinh nghia de dich chu trong app
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false, // Tat chu banner debug
      home: initialScreen, // Man hinh hien thi dau tien
    );
  }
}
