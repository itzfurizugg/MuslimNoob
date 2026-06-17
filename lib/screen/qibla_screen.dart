import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../services/qibla_service.dart';

class QiblaScreen extends StatefulWidget {
  final bool isVisible;
  const QiblaScreen({super.key, this.isVisible = true});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  double? _qiblaDirection;
  double _compassHeading = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = 'Mendeteksi lokasi...';
  bool _wasPointingQibla = false; // ✅ tambahan
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCompass();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QiblaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startCompass();
      } else {
        _stopCompass();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isVisible) return;

    if (state == AppLifecycleState.resumed) {
      _startCompass();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopCompass();
    }
  }

  Future<void> _init() async {
    await _requestPermissions();
    await _getUserLocation();
    _startCompass();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _errorMessage = 'Izin lokasi diperlukan untuk menentukan arah kiblat.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final qibla = QiblaService.getQiblaDirection(
        userLat: position.latitude,
        userLng: position.longitude,
      );

      String locationName = 'Lokasi tidak diketahui';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.subLocality,
            p.locality,
            p.subAdministrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          locationName = parts.isNotEmpty
              ? parts.join(', ')
              : (p.administrativeArea ?? 'Lokasi tidak diketahui');
        }
      } catch (_) {
        locationName =
            '${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°';
      }

      setState(() {
        _qiblaDirection = qibla;
        _locationName = locationName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _vibrateQibla() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    final hasAmplitude = await Vibration.hasAmplitudeControl();
    if (hasAmplitude) {
      Vibration.vibrate(
        pattern: [0, 100, 80, 100, 80, 200],
        intensities: [0, 128, 0, 128, 0, 255],
      );
    } else {
      Vibration.vibrate(pattern: [0, 100, 80, 100, 80, 200]);
    }
  }

  void _startCompass() {
    if (!widget.isVisible) return;
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _compassHeading = event.heading!);
        final nowPointing = _isPointingQibla;
        if (nowPointing && !_wasPointingQibla) {
          _vibrateQibla();
        }
        _wasPointingQibla = nowPointing;
      }
    });
  }

  void _stopCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  double get _needleAngle {
    if (_qiblaDirection == null) return 0;
    return (_qiblaDirection! - _compassHeading) * pi / 180;
  }

  bool get _isPointingQibla {
    if (_qiblaDirection == null) return false;
    double diff = (_qiblaDirection! - _compassHeading).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff <= 5;
  }

  String _getCompassDirection(double heading) {
    const dirs = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
    return dirs[((heading + 22.5) / 45).floor() % 8];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _init();
              },
              icon: Icon(Icons.refresh),
              label: Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B6B),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        160,
      ), // padding bawah utk navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2),
          Text(
            'Arah Kiblat',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24),
          _buildArahKiblatCard(),
          SizedBox(height: 16),
          _buildKompasLingkaran(),
          SizedBox(height: 16),
          _buildDerajatCard(),
          SizedBox(height: 16),
          _buildPeringatan(),
        ],
      ),
    );
  }

  Widget _buildDerajatCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _compassHeading.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A6B6B),
                          ),
                        ),
                        TextSpan(
                          text: '°',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Menghadap ${_getCompassDirection(_compassHeading)}',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: isDark ? Colors.white70 : const Color(0xFF1A6B6B), size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKompasLingkaran() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : const Color(0xFF1A6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.explore,
                  color: isDark ? Colors.white : const Color(0xFF1A6B6B),
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Kompas Kiblat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E3333) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const _CompassBackground(),
                Transform.rotate(
                  angle: -_compassHeading * pi / 180,
                  child: const _CompassLabels(),
                ),
                Transform.rotate(
                  angle: _needleAngle,
                  child: _QiblaNeedle(isPointing: _isPointingQibla),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E4F4F) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPointingQibla
                              ? [
                                  const Color(0xFF1A6B6B),
                                  const Color(0xFF0D4A4A),
                                ]
                              : [Colors.grey.shade700, Colors.grey.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mosque,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArahKiblatCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isPointingQibla ? Colors.green.shade800 : Theme.of(context).cardColor,
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _isPointingQibla
                  ? Colors.white.withOpacity(0.2)
                  : (isDark ? Colors.white12 : const Color(0xFF1A6B6B).withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mosque,
              color: _isPointingQibla ? Colors.white : (isDark ? Colors.white : const Color(0xFF1A6B6B)),
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPointingQibla
                      ? 'Tepat Menghadap Kiblat!'
                      : 'Mencari arah Kiblat...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isPointingQibla
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  _isPointingQibla
                      ? 'Anda telah menghadap ke kiblat!'
                      : 'Posisi Kiblat di ${_qiblaDirection!.toStringAsFixed(1)}°',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isPointingQibla
                        ? Colors.white.withOpacity(0.9)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_qiblaDirection!.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isPointingQibla
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1A6B6B)),
                ),
              ),
              Text(
                'dari Utara',
                style: TextStyle(
                  fontSize: 11,
                  color: _isPointingQibla ? Colors.white70 : (isDark ? Colors.grey[400] : Colors.grey[500]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeringatan() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withOpacity(0.1) : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.amber.withOpacity(0.3) : Colors.amber.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800, size: 18),
              SizedBox(width: 6),
              Text(
                'Perhatian',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.amber.shade200 : Colors.brown.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...[
            '📱 Jauhkan HP dari benda logam atau magnet.',
            '🔄 Jika kompas tidak akurat, gerakkan HP membentuk angka 8.',
            '🧱 Di dalam gedung, kompas bisa kurang akurat.',
            '✅ Toleransi arah kiblat ±5° masih dianggap benar.',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                tip,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade100 : Colors.brown.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassLabels extends StatelessWidget {
  const _CompassLabels();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _label('U', 0, -100, isDark, cardinal: true, isNorth: true),
          _label('T', 100, 0, isDark, cardinal: true),
          _label('S', 0, 100, isDark, cardinal: true),
          _label('B', -100, 0, isDark, cardinal: true),
          _label('TL', 70, -70, isDark),
          _label('TG', 70, 70, isDark),
          _label('BD', -70, 70, isDark),
          _label('BL', -70, -70, isDark),
        ],
      ),
    );
  }

  Widget _label(
    String text,
    double dx,
    double dy,
    bool isDark, {
    bool cardinal = false,
    bool isNorth = false,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Text(
        text,
        style: TextStyle(
          fontSize: cardinal ? 16 : 12,
          fontWeight: cardinal ? FontWeight.bold : FontWeight.w500,
          color: isNorth
              ? Colors.red.shade700
              : (cardinal ? (isDark ? Colors.white : const Color(0xFF1A6B6B)) : Colors.grey.shade400),
        ),
      ),
    );
  }
}

class _CompassBackground extends StatelessWidget {
  const _CompassBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(260, 260),
      painter: _CompassBackgroundPainter(),
    );
  }
}

class _CompassBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final Paint tickPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.5;

    final Paint majorTickPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 2.5;

    for (int i = 0; i < 360; i += 10) {
      final double angle = i * pi / 180;
      final bool isMajor = i % 30 == 0;
      final double startRadius = radius - (isMajor ? 18 : 10);

      final Offset p1 = Offset(
        centerX + startRadius * cos(angle),
        centerY + startRadius * sin(angle),
      );
      final Offset p2 = Offset(
        centerX + radius * cos(angle),
        centerY + radius * sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor ? majorTickPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QiblaNeedle extends StatelessWidget {
  final bool isPointing;
  const _QiblaNeedle({required this.isPointing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 220,
      child: CustomPaint(painter: _NeedlePainter(isPointing: isPointing)),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  final bool isPointing;
  _NeedlePainter({required this.isPointing});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    final Path shadowPath = Path();
    shadowPath.moveTo(cx, 0);
    shadowPath.lineTo(w, cy);
    shadowPath.lineTo(cx, h);
    shadowPath.lineTo(0, cy);
    shadowPath.close();
    canvas.drawShadow(shadowPath, Colors.black, 4, true);

    final Path topPath = Path();
    topPath.moveTo(cx, 0);
    topPath.lineTo(w, cy);
    topPath.lineTo(cx, cy);
    topPath.close();

    final Path topPathLeft = Path();
    topPathLeft.moveTo(cx, 0);
    topPathLeft.lineTo(0, cy);
    topPathLeft.lineTo(cx, cy);
    topPathLeft.close();

    final Color topColor1 = isPointing
        ? const Color(0xFF1A6B6B)
        : const Color(0xFF0D4A4A);
    final Color topColor2 = const Color(0xFF1A6B6B);

    paint.shader = LinearGradient(
      colors: [topColor1, topColor2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, cy));
    canvas.drawPath(topPath, paint);

    paint.shader = LinearGradient(
      colors: [topColor1.withOpacity(0.8), topColor2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, w, cy));
    canvas.drawPath(topPathLeft, paint);

    final Path bottomPath = Path();
    bottomPath.moveTo(cx, h);
    bottomPath.lineTo(w * 0.8, cy);
    bottomPath.lineTo(cx, cy);
    bottomPath.close();

    final Path bottomPathLeft = Path();
    bottomPathLeft.moveTo(cx, h);
    bottomPathLeft.lineTo(w * 0.2, cy);
    bottomPathLeft.lineTo(cx, cy);
    bottomPathLeft.close();

    paint.shader = LinearGradient(
      colors: [Colors.grey.shade400, Colors.grey.shade600],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTWH(0, cy, w, h / 2));
    canvas.drawPath(bottomPath, paint);

    paint.shader = LinearGradient(
      colors: [Colors.grey.shade300, Colors.grey.shade500],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTWH(0, cy, w, h / 2));
    canvas.drawPath(bottomPathLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) {
    return oldDelegate.isPointing != isPointing;
  }
}
