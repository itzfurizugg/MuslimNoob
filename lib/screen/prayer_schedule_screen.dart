import 'package:flutter/material.dart';
import '../services/prayer_service.dart';
// import '../services/foreground_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'city_picker_screen.dart';

class PrayerScheduleScreen extends StatefulWidget {
  final City city;
  final bool isTab;

  const PrayerScheduleScreen({
    super.key,
    required this.city,
    this.isTab = false,
  });

  @override
  State<PrayerScheduleScreen> createState() => _PrayerScheduleScreenState();
}

class _PrayerScheduleScreenState extends State<PrayerScheduleScreen> {
  late final PrayerService _service; // ✅ ganti jadi late final
  PrayerSchedule? _schedule;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = PrayerService(); // ✅ inisialisasi di sini
    _loadTodaySchedule();
  }

  Future<void> _loadTodaySchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final schedule = await _service.getScheduleByDate(
        kotaId: widget.city.id,
        date: DateTime.now(),
      );
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });

      if (schedule != null) {
        _savePrayerTimes(schedule);
        // ForegroundService.start();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat jadwal: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[date.weekday]}, ${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _savePrayerTimes(PrayerSchedule s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_subuh', s.subuh);
    await prefs.setString('prayer_dzuhur', s.dzuhur);
    await prefs.setString('prayer_ashar', s.ashar);
    await prefs.setString('prayer_maghrib', s.maghrib);
    await prefs.setString('prayer_isya', s.isya);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('Jadwal Sholat'),
        backgroundColor: const Color(0xFF1A6B6B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_city),
            tooltip: 'Ganti Kota',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CityPickerScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : _schedule == null
          ? _buildNoData()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTodaySchedule,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Data jadwal sholat belum tersedia\nuntuk hari ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CityPickerScreen()),
            ),
            child: const Text('Ganti Kota'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _schedule!;
    final prayers = [
      {'name': 'Subuh', 'time': s.subuh, 'icon': Icons.nightlight_round},
      if (s.terbit != null)
        {'name': 'Terbit', 'time': s.terbit!, 'icon': Icons.wb_sunny_outlined},
      {'name': 'Dzuhur', 'time': s.dzuhur, 'icon': Icons.wb_sunny},
      {'name': 'Ashar', 'time': s.ashar, 'icon': Icons.wb_cloudy},
      {'name': 'Maghrib', 'time': s.maghrib, 'icon': Icons.wb_twilight},
      {'name': 'Isya', 'time': s.isya, 'icon': Icons.nights_stay},
    ];

    return RefreshIndicator(
      onRefresh: _loadTodaySchedule,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A6B6B), Color(0xFF0D4A4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.city.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.city.province,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(DateTime.now()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Waktu Sholat Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A6B6B),
              ),
            ),
            const SizedBox(height: 12),

            ...prayers.map(
              (p) => _buildPrayerCard(
                name: p['name'] as String,
                time: p['time'] as String,
                icon: p['icon'] as IconData,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard({
    required String name,
    required String time,
    required IconData icon,
  }) {
    final isSubuhOrIsya = name == 'Subuh' || name == 'Isya';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSubuhOrIsya
                  ? const Color(0xFF1A6B6B).withOpacity(0.1)
                  : const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isSubuhOrIsya
                  ? const Color(0xFF1A6B6B)
                  : const Color(0xFFF9A825),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            time.substring(0, 5),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A6B6B),
            ),
          ),
        ],
      ),
    );
  }
}
