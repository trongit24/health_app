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
import 'core/services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // 2. Initialize Notification service
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    
    // Check daily notification preference and schedule if active
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('daily_notification_enabled') ?? true;
    if (notificationsEnabled) {
      // Do not request permissions here before runApp(). It will block the UI and cause a white screen.
      // Permissions should be requested inside the App UI (e.g., Home Screen or Onboarding).
      await notificationService.scheduleDailyReminder();
    }
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  // 3. Initialize AI Service
  try {
    await AiService().initialize();
  } catch (e) {
    debugPrint('AI service initialization failed: $e');
  }

  // 4. Determine Initial Route
  Widget initialScreen;
  try {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (!seenOnboarding) {
      initialScreen = const OnboardingScreen();
    } else if (!isLoggedIn) {
      initialScreen = const LoginScreen();
    } else {
      initialScreen = const SoulFlowHomeFrame();
    }
  } catch (e) {
    initialScreen = const OnboardingScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: SoulFlowApp(initialScreen: initialScreen),
    ),
  );
}

class SoulFlowApp extends StatelessWidget {
  final Widget initialScreen;
  const SoulFlowApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'SoulFlow',
      theme: SoulFlowTheme.lightTheme,
      darkTheme: SoulFlowTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
