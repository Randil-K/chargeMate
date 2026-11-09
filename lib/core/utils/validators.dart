import 'package:charge_mate/core/constants/app_constants.dart';

/// Form field validators shared across the app.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phoneRegex = RegExp(r'^(\+94|0)?7\d{8}$');

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Use at least ${AppConstants.minPasswordLength} characters';
    }
    if (!value.contains(RegExp(r'\d'))) return 'Include at least one number';
    return null;
  }

  /// Sri Lankan mobile number, e.g. 0771234567 or +94771234567.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!_phoneRegex.hasMatch(cleaned)) return 'Enter a valid Sri Lankan mobile';
    return null;
  }

  static String? positiveNumber(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid $field';
    return null;
  }
}
