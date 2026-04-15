import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/splash_screen.dart';
import 'screen/auth/login.dart';
import 'screen/auth/register.dart';
import 'screen/home.dart';
import 'screen/city_picker_screen.dart';
import 'screen/prayer_schedule_screen.dart';
// import 'services/notification_service.dart';
// import 'services/foreground_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ryyahvjonscodfcmjaaf.supabase.co',
    anonKey: 'sb_publishable_gRefHEE_JHWhY7XoVIVjmg_6CsTB_xM',
  );

  // Initialize Services
  // await NotificationService().init();
  // ForegroundService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuslimNoob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6B6B)),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
        '/city-picker': (context) => const CityPickerScreen(),
      },
    );
  }
}
