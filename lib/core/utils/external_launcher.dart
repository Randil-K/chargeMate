import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens external apps (Google Maps navigation, phone dialer).
abstract final class ExternalLauncher {
  static Future<bool> navigateTo(double lat, double lng) => _open(Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'));

  static Future<bool> walkTo(double lat, double lng) => _open(Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking'));

  static Future<bool> call(String number) =>
      _open(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static void showFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the app on this device.')),
    );
  }
}
