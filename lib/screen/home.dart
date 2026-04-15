import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_service.dart';
import 'city_picker_screen.dart';
import 'prayer_schedule_screen.dart';
import 'qibla_screen.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  City? _selectedCity;

  @override
  void initState() {
    super.initState();
    _checkSavedCity();
  }

  Future<void> _checkSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final cityId = prefs.getInt('selected_city_id');
    final cityName = prefs.getString('selected_city_name');
    final cityProvince = prefs.getString('selected_city_province') ?? '';
    final cityTimezone =
        prefs.getString('selected_city_timezone') ?? 'Asia/Jakarta';

    if (cityId != null && cityName != null) {
      setState(() {
        _selectedCity = City(
          id: cityId,
          name: cityName,
          province: cityProvince,
          timezone: cityTimezone,
        );
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CityPickerScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F0E8),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A6B6B)),
        ),
      );
    }

    if (_selectedCity == null) return const SizedBox.shrink();

    final List<Widget> tabs = [
      PrayerScheduleScreen(city: _selectedCity!, isTab: true),
      const QiblaScreen(),
      const Scaffold(
        backgroundColor: Color(0xFFF5F0E8),
        body: Center(child: Text('Doa & Dzikir - Coming Soon')),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF1A6B6B),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Kiblat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Doa dan Dzikir',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
