import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/prayer_service.dart';
import 'home.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  late final PrayerService _service;
  final TextEditingController _searchController = TextEditingController();

  List<String> _allProvinces = [];
  List<String> _filteredProvinces = [];
  
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  
  String? _selectedProvince;
  bool _isLoading = true;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _service = PrayerService();
    _loadProvinces();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoading = true);
    try {
      final provinces = await _service.getProvinces();
      setState(() {
        _allProvinces = provinces;
        _filteredProvinces = provinces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat daftar provinsi: $e')));
      }
    }
  }

  Future<void> _loadCities(String province) async {
    setState(() {
      _selectedProvince = province;
      _isLoading = true;
      _searchController.clear();
    });
    try {
      final cities = await _service.getCitiesByProvince(province);
      setState(() {
        _allCities = cities;
        _filteredCities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _selectedProvince = null;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat daftar kota: $e')));
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_selectedProvince == null) {
        _filteredProvinces = _allProvinces.where((prov) {
          return prov.toLowerCase().contains(query);
        }).toList();
      } else {
        _filteredCities = _allCities.where((city) {
          return city.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectCity(City city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_city_id', city.id);
    await prefs.setString('selected_city_name', city.name);
    await prefs.setString('selected_city_province', city.province);
    await prefs.setString('selected_city_timezone', city.timezone);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _goBack() {
    if (_selectedProvince != null) {
      setState(() {
        _selectedProvince = null;
        _searchController.clear();
        _filteredProvinces = _allProvinces;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? provName = place.administrativeArea;
        String? cityName = place.subAdministrativeArea ?? place.locality;
        
        if (provName != null && cityName != null) {
          // Normalisasi nama provinsi
          String targetProv = provName.toUpperCase();
          if (targetProv.contains("DAERAH KHUSUS IBUKOTA")) targetProv = "DKI JAKARTA";
          if (targetProv.contains("DAERAH ISTIMEWA")) targetProv = "D.I. YOGYAKARTA";
          if (targetProv.contains("BANTEN")) targetProv = "BANTEN"; // Handle edge cases
          
          // Cari provinsi dari API
          final provinces = _allProvinces.isEmpty ? await _service.getProvinces() : _allProvinces;
          String? matchedProv;
          for (var p in provinces) {
            if (p.toUpperCase() == targetProv || targetProv.contains(p.toUpperCase()) || p.toUpperCase().contains(targetProv)) {
              matchedProv = p;
              break;
            }
          }
          
          if (matchedProv != null) {
            final cities = await _service.getCitiesByProvince(matchedProv);
            
            // Normalisasi nama kota
            String targetCity = cityName.toUpperCase();
            if (targetCity.startsWith("KABUPATEN ")) {
              targetCity = targetCity.replaceFirst("KABUPATEN ", "KAB. ");
            }
            
            City? matchedCity;
            for (var c in cities) {
              if (c.name.toUpperCase() == targetCity || c.name.toUpperCase().contains(targetCity.replaceAll("KAB. ", "")) || targetCity.contains(c.name.toUpperCase().replaceAll("KAB. ", ""))) {
                matchedCity = c;
                break;
              }
            }
            
            if (matchedCity != null) {
              await _selectCity(matchedCity);
              return; // Sukses
            } else {
              throw Exception("Kota tidak ditemukan di database API ($cityName).");
            }
          } else {
            throw Exception("Provinsi tidak ditemukan di database API ($provName).");
          }
        } else {
          throw Exception("Gagal mendapatkan nama kota/provinsi dari lokasi.");
        }
      } else {
        throw Exception("Gagal mendapatkan alamat dari lokasi.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal deteksi lokasi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  if (Navigator.canPop(context) || _selectedProvince != null)
                    _buildGlassButton(
                      onPressed: _goBack,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new, size: 16),
                          SizedBox(width: 6),
                          Text('Kembali'),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 🔥 TITLE
            Padding(
              padding: EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                _selectedProvince == null ? 'Pilih Provinsi' : 'Pilih Kota',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ),

            // 🔥 SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _selectedProvince == null ? 'Cari provinsi...' : 'Cari kota...',
                  hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500]),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Color(0xFF1A6B6B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // 🔥 AUTO DETECT LOCATION BUTTON
            if (_selectedProvince == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: InkWell(
                  onTap: _isLocating ? null : _autoDetectLocation,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLocating 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.my_location_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text(
                          _isLocating ? 'Mendeteksi Lokasi...' : 'Gunakan Lokasi Saat Ini',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 🔥 LIST
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A6B6B),
                      ),
                    )
                  : (_selectedProvince == null ? _buildProvincesList() : _buildCitiesList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvincesList() {
    if (_filteredProvinces.isEmpty) {
      return Center(
        child: Text('Provinsi tidak ditemukan', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredProvinces.length,
      separatorBuilder: (_, _) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final province = _filteredProvinces[index];
        return GestureDetector(
          onTap: () => _loadCities(province),
          child: _buildListItem(province, 'Provinsi'),
        );
      },
    );
  }

  Widget _buildCitiesList() {
    if (_filteredCities.isEmpty) {
      return Center(
        child: Text('Kota tidak ditemukan', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredCities.length,
      separatorBuilder: (_, _) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        return GestureDetector(
          onTap: () => _selectCity(city),
          child: _buildListItem(city.name, city.province),
        );
      },
    );
  }

  Widget _buildListItem(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey[300],
            size: 18,
          ),
        ],
      ),
    );
  }

  // 🔥 GLASS BUTTON FIX
  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              child: IconTheme(
                data: IconThemeData(color: Theme.of(context).colorScheme.onSurface, size: 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
