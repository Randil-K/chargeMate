import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/vehicle/data/models/vehicle_model.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/domain/repositories/vehicle_repository.dart';

/// Local-first vehicle repository.
///
/// Vehicles are persisted per device in SharedPreferences. When the Spring
/// Boot backend is ready, a remote data source can sync `/api/vehicles`
/// without changing any domain or presentation code.
class VehicleRepositoryImpl implements VehicleRepository {
  static const _key = 'user_vehicles';
  static const _catalogAsset = 'assets/mock_data/vehicles.json';

  final SharedPreferences _prefs;
  List<VehicleSpec>? _catalog;

  VehicleRepositoryImpl(this._prefs);

  List<Vehicle> _read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Vehicle>> _write(List<Vehicle> list) async {
    // Guarantee exactly one primary vehicle when the list is non-empty.
    if (list.isNotEmpty && !list.any((v) => v.isPrimary)) {
      list[0] = list[0].copyWith(isPrimary: true);
    }
    await _prefs.setString(
        _key, jsonEncode(list.map(VehicleModel.toJson).toList()));
    return list;
  }

  Future<Either<Failure, List<Vehicle>>> _guard(
      Future<List<Vehicle>> Function() body) async {
    try {
      return Right(await body());
    } catch (_) {
      return const Left(CacheFailure(message: 'Could not save vehicles.'));
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async =>
      _guard(() async => _read());

  @override
  Future<Either<Failure, List<Vehicle>>> addVehicle(Vehicle vehicle) =>
      _guard(() async {
        final list = _read();
        final v = vehicle.copyWith(
          id: 'v-${DateTime.now().millisecondsSinceEpoch}',
          isPrimary: list.isEmpty,
        );
        return _write([...list, v]);
      });

  @override
  Future<Either<Failure, List<Vehicle>>> updateVehicle(Vehicle vehicle) =>
      _guard(() async => _write(
          _read().map((v) => v.id == vehicle.id ? vehicle : v).toList()));

  @override
  Future<Either<Failure, List<Vehicle>>> deleteVehicle(String id) =>
      _guard(() async => _write(_read().where((v) => v.id != id).toList()));

  @override
  Future<Either<Failure, List<Vehicle>>> setPrimary(String id) =>
      _guard(() async => _write(
          _read().map((v) => v.copyWith(isPrimary: v.id == id)).toList()));

  @override
  Future<Either<Failure, List<VehicleSpec>>> getSpecCatalog() async {
    try {
      _catalog ??= (jsonDecode(await rootBundle.loadString(_catalogAsset))
              as List)
          .map((e) => VehicleSpecModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(_catalog!);
    } catch (_) {
      return const Left(ServerFailure(message: 'Could not load vehicle catalog.'));
    }
  }
}
