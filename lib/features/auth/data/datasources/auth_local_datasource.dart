import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/features/auth/data/models/user_model.dart';

/// Persists the session on-device.
///
/// - JWT tokens → [FlutterSecureStorage] (Android Keystore / iOS Keychain)
/// - Non-sensitive cached profile → [SharedPreferences]
class AuthLocalDataSource {
  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  const AuthLocalDataSource(this._secure, this._prefs);

  Future<void> saveSession(AuthResponseModel auth) async {
    try {
      await Future.wait([
        _secure.write(
            key: AppConstants.accessTokenKey, value: auth.accessToken),
        _secure.write(
            key: AppConstants.refreshTokenKey, value: auth.refreshToken),
        cacheUser(auth.user),
      ]);
    } catch (_) {
      throw const CacheException(message: 'Could not save your session.');
    }
  }

  Future<void> cacheUser(UserModel user) =>
      _prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));

  Future<UserModel?> getCachedUser() async {
    final token = await _secure.read(key: AppConstants.accessTokenKey);
    final raw = _prefs.getString(AppConstants.userDataKey);
    if (token == null || raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await Future.wait([
      _secure.delete(key: AppConstants.accessTokenKey),
      _secure.delete(key: AppConstants.refreshTokenKey),
      _prefs.remove(AppConstants.userDataKey),
    ]);
  }

  bool get isOnboardingComplete =>
      _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete() =>
      _prefs.setBool(AppConstants.onboardingCompleteKey, true);
}
