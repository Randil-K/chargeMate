import 'package:geolocator/geolocator.dart';

import 'package:charge_mate/core/constants/app_constants.dart';

/// Simple value object for a geographic coordinate.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  static const colombo =
      GeoPoint(AppConstants.defaultLat, AppConstants.defaultLng);
}

/// Result of a location lookup — always returns a usable point,
/// plus a flag that tells the UI whether it is the real GPS fix
/// or the fallback (Colombo city centre).
class LocationResult {
  final GeoPoint point;
  final bool isFallback;
  final String? message;

  const LocationResult(this.point, {this.isFallback = false, this.message});
}

/// Wraps Geolocator with safe, non-blocking fallbacks:
/// - Never freezes the UI thread
/// - Tries last-known position first (0 ms)
/// - Capped at 2.5 second timeout
/// - Always falls back to Colombo so the app works reliably on emulators.
class LocationService {
  GeoPoint? _lastKnown;

  GeoPoint get lastKnown => _lastKnown ?? GeoPoint.colombo;

  Future<LocationResult> getCurrentLocation() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 1), onTimeout: () => false);

      if (!isEnabled) {
        return const LocationResult(
          GeoPoint.colombo,
          isFallback: true,
          message: 'Location services off. Showing Colombo.',
        );
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 1), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          GeoPoint.colombo,
          isFallback: true,
          message: 'Showing Colombo stations.',
        );
      }

      // Try last-known location first (instant on Android)
      final lastPos = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 1), onTimeout: () => null);

      if (lastPos != null) {
        _lastKnown = GeoPoint(lastPos.latitude, lastPos.longitude);
        return LocationResult(_lastKnown!);
      }

      // If no last-known, request with balanced accuracy and 2.5s timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      ).timeout(const Duration(seconds: 2));

      _lastKnown = GeoPoint(position.latitude, position.longitude);
      return LocationResult(_lastKnown!);
    } catch (_) {
      return const LocationResult(
        GeoPoint.colombo,
        isFallback: true,
        message: 'Showing Colombo stations.',
      );
    }
  }
}
