import 'dart:convert';
import 'package:http/http.dart' as http;

class City {
  final int id;
  final String name;
  final String province;
  final String timezone;

  City({
    this.id = 0,
    required this.name,
    required this.province,
    required this.timezone,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] ?? 0,
    name: json['name'] ?? json['kabkota'] ?? '',
    province: json['province'] ?? json['provinsi'] ?? '',
    timezone: json['timezone'] ?? 'Asia/Jakarta',
  );
}

class PrayerSchedule {
  final int id;
  final int kotaId;
  final DateTime tanggal;
  final String subuh;
  final String? terbit;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  PrayerSchedule({
    this.id = 0,
    this.kotaId = 0,
    required this.tanggal,
    required this.subuh,
    this.terbit,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) => PrayerSchedule(
    id: 0,
    kotaId: 0,
    tanggal: DateTime.parse(json['tanggal_lengkap'] ?? json['date']),
    subuh: json['subuh'],
    terbit: json['terbit'] ?? json['dhuha'], // Use dhuha as terbit fallback or keep as is.
    dzuhur: json['dzuhur'],
    ashar: json['ashar'],
    maghrib: json['maghrib'],
    isya: json['isya'],
  );
}

class PrayerService {
  static const String _baseUrl = 'https://equran.id/api/v2/shalat';

  /// Ambil daftar provinsi
  Future<List<String>> getProvinces() async {
    final response = await http.get(Uri.parse('$_baseUrl/provinsi'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['data']);
    }
    throw Exception('Gagal mengambil daftar provinsi');
  }

  /// Ambil daftar kota berdasarkan provinsi
  Future<List<City>> getCitiesByProvince(String province) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/kabkota'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'provinsi': province}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<String> cities = List<String>.from(data['data']);
      return cities
          .map((c) => City(name: c, province: province, timezone: 'Asia/Jakarta'))
          .toList();
    }
    throw Exception('Gagal mengambil daftar kota');
  }

  /// Ambil semua kota (Deprecated, since we fetch by province now)
  Future<List<City>> getCities() async {
    return [];
  }

  /// Ambil jadwal sholat berdasarkan kota dan tanggal tertentu
  Future<PrayerSchedule?> getScheduleByDate({
    required City city,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provinsi': city.province,
        'kabkota': city.name,
        'bulan': date.month,
        'tahun': date.year,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List jadwalList = data['data']['jadwal'];
      
      final String targetDateStr = date.toIso8601String().substring(0, 10);
      
      for (var item in jadwalList) {
        if (item['tanggal_lengkap'] == targetDateStr) {
          return PrayerSchedule.fromJson(item);
        }
      }
    }
    return null;
  }

  /// Ambil jadwal sholat 1 bulan penuh
  Future<List<PrayerSchedule>> getScheduleByMonth({
    required City city,
    required int month,
    required int year,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provinsi': city.province,
        'kabkota': city.name,
        'bulan': month,
        'tahun': year,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List jadwalList = data['data']['jadwal'];
      return jadwalList.map((e) => PrayerSchedule.fromJson(e)).toList();
    }
    return [];
  }
}
