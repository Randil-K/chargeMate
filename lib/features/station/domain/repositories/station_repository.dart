import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/services/location_service.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

/// Contract for charging station data (mirrors `/api/stations/*`).
abstract class StationRepository {
  /// All stations, annotated with distance from [origin] and sorted nearest first.
  Future<Either<Failure, List<ChargingStation>>> getStations(GeoPoint origin);

  Future<Either<Failure, ChargingStation>> getStationById(
    String id, {
    GeoPoint? origin,
  });

  Future<Either<Failure, Set<String>>> getFavouriteIds();

  /// Adds or removes a favourite and returns the updated set.
  Future<Either<Failure, Set<String>>> toggleFavourite(String stationId);
}
