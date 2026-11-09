import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/services/location_service.dart';
import 'package:charge_mate/core/utils/distance_utils.dart';
import 'package:charge_mate/features/station/data/datasources/station_datasources.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/domain/repositories/station_repository.dart';

class StationRepositoryImpl implements StationRepository {
  final StationRemoteDataSource _remote;
  final StationLocalDataSource _local;

  const StationRepositoryImpl(this._remote, this._local);

  ChargingStation _withDistance(ChargingStation s, GeoPoint origin) =>
      s.copyWith(
        distanceKm: DistanceUtils.haversineKm(
            origin.latitude, origin.longitude, s.latitude, s.longitude),
      );

  @override
  Future<Either<Failure, List<ChargingStation>>> getStations(
      GeoPoint origin) async {
    try {
      final stations = await _remote.fetchStations();
      final result = stations.map((s) => _withDistance(s, origin)).toList()
        ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ChargingStation>> getStationById(
    String id, {
    GeoPoint? origin,
  }) async {
    try {
      final stations = await _remote.fetchStations();
      final match = stations.where((s) => s.id == id);
      if (match.isEmpty) {
        return const Left(NotFoundFailure(message: 'Station not found.'));
      }
      final station = match.first;
      return Right(origin == null ? station : _withDistance(station, origin));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getFavouriteIds() async {
    try {
      return Right(_local.getFavourites());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> toggleFavourite(String stationId) async {
    try {
      return Right(await _local.toggle(stationId));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
