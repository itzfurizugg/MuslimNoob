import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'services/prayer_notif_service.dart';
import 'screen/splash_screen.dart';
import 'screen/auth/login.dart';
import 'screen/auth/register.dart';
import 'screen/home.dart';
import 'screen/city_picker_screen.dart';
import 'screen/dua/dua_category_screen.dart';

import 'services/theme_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi timezone database
  tz.initializeTimeZones();

  await Supabase.initialize(
    url: 'https://ryyahvjonscodfcmjaaf.supabase.co',
    anonKey: 'sb_publishable_gRefHEE_JHWhY7XoVIVjmg_6CsTB_xM',
  );

  // Inisialisasi notification plugin & minta izin
  await PrayerNotifService().init();
  
  // Inisialisasi Theme Service
  await ThemeService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'MuslimNoob',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomeScreen(),
            '/city-picker': (context) => const CityPickerScreen(),
            '/dua': (context) => const DuaCategoryScreen(),
          },
        );
      },
    );
  }
}
