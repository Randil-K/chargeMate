import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charge_mate/core/constants/api_endpoints.dart';
import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/features/station/data/models/charging_station_model.dart';

/// Remote station source contract.
abstract class StationRemoteDataSource {
  Future<List<ChargingStationModel>> fetchStations();
}

/// Spring Boot implementation (`GET /api/stations`).
class ApiStationRemoteDataSource implements StationRemoteDataSource {
  final Dio _dio;
  const ApiStationRemoteDataSource(this._dio);

  @override
  Future<List<ChargingStationModel>> fetchStations() async {
    try {
      final res = await _dio.get('/stations');
      return (res.data as List)
          .map((e) => ChargingStationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(statusCode: e.response?.statusCode);
    }
  }

  /// Example of the nearby endpoint for when the backend supports
  /// server-side geo queries (MySQL spatial index / Haversine SQL).
  Future<List<ChargingStationModel>> fetchNearby(
      double lat, double lng, double radiusKm) async {
    final res = await _dio.get(ApiEndpoints.nearbyStations,
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusKm});
    return (res.data as List)
        .map((e) => ChargingStationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Offline mock reading the bundled sample dataset.
class MockStationRemoteDataSource implements StationRemoteDataSource {
  static const _asset = 'assets/mock_data/charging_stations.json';
  List<ChargingStationModel>? _cache;

  @override
  Future<List<ChargingStationModel>> fetchStations() async {
    if (_cache != null) return _cache!;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      final raw = await rootBundle.loadString(_asset);
      _cache = (jsonDecode(raw) as List)
          .map((e) => ChargingStationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cache!;
    } catch (e) {
      throw ServerException(message: 'Failed to load station data: $e');
    }
  }
}

/// Stores the user's favourite station IDs on-device.
class StationLocalDataSource {
  static const _favKey = 'favourite_station_ids';
  final SharedPreferences _prefs;
  const StationLocalDataSource(this._prefs);

  Set<String> getFavourites() =>
      (_prefs.getStringList(_favKey) ?? const []).toSet();

  Future<Set<String>> toggle(String id) async {
    final favs = getFavourites();
    if (!favs.remove(id)) favs.add(id);
    await _prefs.setStringList(_favKey, favs.toList());
    return favs;
  }
}
