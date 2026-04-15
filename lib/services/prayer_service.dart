import 'package:supabase_flutter/supabase_flutter.dart';

class City {
  final int id;
  final String name;
  final String province;
  final String timezone;

  City({
    required this.id,
    required this.name,
    required this.province,
    required this.timezone,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'],
    name: json['name'],
    province: json['province'],
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
    required this.id,
    required this.kotaId,
    required this.tanggal,
    required this.subuh,
    this.terbit,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) => PrayerSchedule(
    id: json['id'],
    kotaId: json['kota_id'],
    tanggal: DateTime.parse(json['date']),
    subuh: json['subuh'],
    terbit: json['terbit'],
    dzuhur: json['dzuhur'],
    ashar: json['ashar'],
    maghrib: json['maghrib'],
    isya: json['isya'],
  );
}

class PrayerService {
  final _supabase = Supabase.instance.client;

  /// Ambil semua kota, diurutkan berdasarkan nama
  Future<List<City>> getCities() async {
    final response = await _supabase
        .from('cities')
        .select()
        .order('id', ascending: true);

    return (response as List).map((e) => City.fromJson(e)).toList();
  }

  /// Ambil jadwal sholat berdasarkan kota dan tanggal tertentu
  Future<PrayerSchedule?> getScheduleByDate({
    required int kotaId,
    required DateTime date,
  }) async {
    final tanggal = date.toIso8601String().substring(0, 10); // YYYY-MM-DD

    final response = await _supabase
        .from('prayer_schedules')
        .select()
        .eq('kota_id', kotaId)
        .eq('date', tanggal)
        .maybeSingle();

    if (response == null) return null;
    return PrayerSchedule.fromJson(response);
  }

  /// Ambil jadwal sholat 1 bulan penuh
  Future<List<PrayerSchedule>> getScheduleByMonth({
    required int kotaId,
    required int month,
    required int year,
  }) async {
    final from = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final to =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final response = await _supabase
        .from('prayer_schedules')
        .select()
        .eq('kota_id', kotaId)
        .gte('date', from)
        .lte('date', to)
        .order('date', ascending: true);

    return (response as List).map((e) => PrayerSchedule.fromJson(e)).toList();
  }
}
