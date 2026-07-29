import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/auth/email_verification_page.dart';
import 'package:chatapp/pages/auth/login_page.dart';
import 'package:chatapp/pages/home_page.dart';
import 'package:chatapp/providers/app_provider.dart';
import 'package:chatapp/service/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Oturum kontrolü
    final value = await HelperFunction.getUserLoggedInStatus();
    if (value != null) {
      setState(() => _isSignedIn = value);
    }

    // Provider'ı güncelle
    if (mounted) {
      await context.read<AppProvider>().loadUser();
    }

    // Bildirim servisi
    await _notificationService.initialize();
    final userEmail = await HelperFunction.getUserEmailSF();
    if (userEmail != null) {
      await _notificationService.saveFcmToken(userEmail);
      _notificationService.listenTokenRefresh(userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppProvider>().themeMode;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A11CB), // Deep Purple
          primary: const Color(0xFF6A11CB),
          secondary: const Color(0xFF2575FC), // Neon Blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Off-white
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 10,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A11CB),
          primary: const Color(0xFF6A11CB),
          secondary: const Color(0xFF2575FC),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Gece mavisi
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 10,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
      ),
      home: _getInitialPage(),
    );
  }

  Widget _getInitialPage() {
    if (!_isSignedIn) return const LoginPage();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      return const EmailVerificationPage();
    }
    
    return const HomePage();
  }
}