import 'dart:math' as math;

/// Geographic distance helpers.
abstract final class DistanceUtils {
  static const double _earthRadiusKm = 6371.0;

  /// Great-circle distance between two coordinates using the Haversine formula.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Human friendly distance, e.g. "850 m" or "4.2 km".
  static String format(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  /// Estimated walking time at an average pace of 5 km/h.
  static int walkingMinutes(double km) => (km / 5 * 60).ceil();

  static double _toRad(double deg) => deg * math.pi / 180;
}
