import 'dart:math';

class QiblaService {
  // Koordinat Ka'bah di Makkah
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  /// Hitung arah kiblat dari koordinat user (dalam derajat, 0-360)
  static double getQiblaDirection({
    required double userLat,
    required double userLng,
  }) {
    final lat1 = _toRadian(userLat);
    final lat2 = _toRadian(_kaabaLat);
    final dLng = _toRadian(_kaabaLng - userLng);

    final y = sin(dLng);
    final x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLng);

    double bearing = atan2(y, x);
    bearing = _toDegree(bearing);
    return (bearing + 360) % 360; // Normalkan ke 0-360
  }

  static double _toRadian(double degree) => degree * pi / 180;
  static double _toDegree(double radian) => radian * 180 / pi;
}