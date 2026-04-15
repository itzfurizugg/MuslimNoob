import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_service.dart';
import 'home.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  late final PrayerService _service; // ✅ ganti jadi late final
  final TextEditingController _searchController = TextEditingController();

  List<City> _allCities = [];
  List<City> _filteredCities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = PrayerService(); // ✅ inisialisasi di sini
    _loadCities();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _service.getCities();
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar kota: $e')));
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = _allCities.where((city) {
        return city.name.toLowerCase().contains(query) ||
            city.province.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _selectCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_city_id', city.id);
    await prefs.setString('selected_city_name', city.name);
    await prefs.setString('selected_city_province', city.province);
    await prefs.setString('selected_city_timezone', city.timezone);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Pilih Kota'),
        backgroundColor: const Color(0xFF1A6B6B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kota atau provinsi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // List kota
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCities.isEmpty
                ? const Center(child: Text('Kota tidak ditemukan'))
                : ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1A6B6B),
                          child: Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          city.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(city.province),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectCity(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
