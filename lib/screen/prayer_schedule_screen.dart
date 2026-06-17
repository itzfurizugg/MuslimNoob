import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hijri/hijri_calendar.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/prayer_service.dart';
import '../services/prayer_notif_service.dart';
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
  late final PrayerService _service;
  PrayerSchedule? _schedule;
  bool _isLoading = true;
  String? _errorMessage;
  String? _fullName;

  Timer? _timer;
  DateTime _now = DateTime.now();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _service = PrayerService();
    _loadTodaySchedule();
    _loadUserName();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (mounted) {
      setState(() {
        _fullName = user?.userMetadata?['full_name'] as String?;
      });
    }
  }

  Future<void> _loadTodaySchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final schedule = await _service.getScheduleByDate(
        city: widget.city,
        date: DateTime.now(),
      );
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });

      if (schedule != null) {
        _savePrayerTimes(schedule);
        // Schedule notifikasi adzan untuk hari ini
        try {
          await PrayerNotifService().schedulePrayerNotifications(
            schedule,
            widget.city.timezone,
          );
          print('✅ [NOTIF] Penjadwalan notifikasi adzan selesai');
        } catch (e) {
          print('❌ [NOTIF] Error saat menjadwalkan notifikasi: $e');
        }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Tombol floating untuk Ubah Kota, bergaya liquid glass
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Biar gak ketutup navbar
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CityPickerScreen()),
                  ).then((_) {
                    // If they return and city was changed, we might need to reload.
                    // But typically, a better way is to pushReplacement to Home from CityPicker
                    // when an actual selection is made. For now, just allow returning.
                  }),
              backgroundColor: Colors.white.withOpacity(0.5),
              elevation: 0,
              icon: Icon(Icons.location_city, color: Color(0xFF1A6B6B)),
              label: Text(
                'Ubah Kota',
                style: TextStyle(
                  color: Color(0xFF1A6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _schedule == null
            ? _buildNoData()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTodaySchedule,
            child: Text('Coba Lagi'),
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
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Data jadwal sholat belum tersedia\nuntuk hari ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CityPickerScreen()),
            ),
            child: Text('Ganti Kota'),
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
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          160,
        ), // padding bawah untuk navbar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headings inline dalam body
            Text(
              'Assalamu\'alaikum,',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              _fullName ?? 'Saudaraku',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24),

            // Swipeable Clock / Calendar Card
            SizedBox(
              height: 200,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [_buildClockCard(), _buildHijriCard()],
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 2,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: const Color(0xFF1A6B6B),
                  dotColor: Colors.grey.shade300,
                ),
              ),
            ),

            SizedBox(height: 24),
            Text(
              'Waktu Sholat Hari Ini',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),

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

  Widget _buildClockCard() {
    String hh = _now.hour.toString().padLeft(2, '0');
    String mm = _now.minute.toString().padLeft(2, '0');
    String ss = _now.second.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ), // Untuk pageview padding
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6B6B), Color(0xFF0D4A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B6B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.city.name}, ${widget.city.province}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          /* Jam */
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$hh:$mm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: 8),
              Text(
                ss,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            _formatDate(_now),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHijriCard() {
    final today = HijriCalendar.now();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE89813),
            Color(0xFFB06F0B),
          ], // Warna emas untuk hijri
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE89813).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dark_mode_rounded, color: Colors.white, size: 32),
          const Spacer(),
          Text(
            '${today.hDay} ${today.longMonthName}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${today.hYear} Hijriyah',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({
    required String name,
    required String time,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSubuhOrIsya = name == 'Subuh' || name == 'Isya';
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSubuhOrIsya
                  ? primaryColor.withOpacity(0.1)
                  : (theme.brightness == Brightness.dark ? Colors.orange.withOpacity(0.1) : const Color(0xFFFFF9C4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isSubuhOrIsya
                  ? primaryColor
                  : (theme.brightness == Brightness.dark ? Colors.orange : const Color(0xFFF9A825)),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            time.substring(0, 5),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
