import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charge_mate/core/constants/api_endpoints.dart';
import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/features/auth/data/models/user_model.dart';

/// Remote authentication contract (mirrors Spring Boot `/api/auth/*`).
abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<UserModel> updateProfile(UserModel user);
}

// ═════════════════════════════════════════════════════════════════════
// Real implementation — used once the Spring Boot backend is running.
// ═════════════════════════════════════════════════════════════════════
class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  final Dio _dio;
  const ApiAuthRemoteDataSource(this._dio);

  @override
  Future<AuthResponseModel> login(String email, String password) => _guard(
        () async {
          final res = await _dio.post(ApiEndpoints.login,
              data: {'email': email, 'password': password});
          return AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
        },
      );

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      _guard(() async {
        final res = await _dio.post(ApiEndpoints.register, data: {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phone,
          'password': password,
        });
        return AuthResponseModel.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<void> requestPasswordReset(String email) => _guard(() async {
        await _dio.post('/auth/forgot-password', data: {'email': email});
      });

  @override
  Future<UserModel> updateProfile(UserModel user) => _guard(() async {
        final res =
            await _dio.put(ApiEndpoints.userProfile, data: user.toJson());
        return UserModel.fromJson(res.data as Map<String, dynamic>);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] as String? ?? 'Request failed')
          : 'Request failed';
      if (code == 401 || code == 403) {
        throw AuthException(message: msg, statusCode: code);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      throw ServerException(message: msg, statusCode: code);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════
// Mock implementation — lets the app be demoed fully offline.
// Users are persisted in SharedPreferences so sign-ups survive restarts.
// NOTE: The real backend hashes passwords with BCrypt; this mock does not.
// ═════════════════════════════════════════════════════════════════════
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  static const _usersKey = 'mock_backend_users';
  static const demoEmail = 'demo@chargemate.lk';
  static const demoPassword = 'demo1234';

  final SharedPreferences _prefs;
  MockAuthRemoteDataSource(this._prefs) {
    _seedDemoUser();
  }

  Map<String, dynamic> get _users =>
      jsonDecode(_prefs.getString(_usersKey) ?? '{}') as Map<String, dynamic>;

  Future<void> _save(Map<String, dynamic> users) =>
      _prefs.setString(_usersKey, jsonEncode(users));

  void _seedDemoUser() {
    final users = _users;
    if (users.containsKey(demoEmail)) return;
    users[demoEmail] = {
      'password': demoPassword,
      'user': UserModel(
        id: 'u-demo',
        fullName: 'Kasun Perera',
        email: demoEmail,
        phone: '0771234567',
        preferredCity: 'Colombo',
        preferredCategories: const ['Coffee', 'Restaurants'],
        createdAt: DateTime(2026, 1, 15),
      ).toJson(),
    };
    _save(users);
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 900));

  AuthResponseModel _tokensFor(UserModel user) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return AuthResponseModel(
      accessToken: 'mock.access.${user.id}.$stamp',
      refreshToken: 'mock.refresh.${user.id}.$stamp',
      user: user,
    );
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    await _latency();
    final record = _users[email] as Map<String, dynamic>?;
    if (record == null || record['password'] != password) {
      throw const AuthException(
        message: 'Incorrect email or password.',
        statusCode: 401,
      );
    }
    return _tokensFor(
        UserModel.fromJson(record['user'] as Map<String, dynamic>));
  }

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _latency();
    final users = _users;
    if (users.containsKey(email)) {
      throw const ServerException(
        message: 'An account with this email already exists.',
        statusCode: 409,
      );
    }
    final user = UserModel(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );
    users[email] = {'password': password, 'user': user.toJson()};
    await _save(users);
    return _tokensFor(user);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _latency();
    // Always succeed to avoid leaking which emails are registered.
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final users = _users;
    final record = users[user.email] as Map<String, dynamic>?;
    if (record == null) throw const NotFoundException();
    record['user'] = user.toJson();
    await _save(users);
    return user;
  }
}
