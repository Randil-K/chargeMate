import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/services/location_service.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/domain/entities/station_filter.dart';
import 'package:charge_mate/features/station/domain/repositories/station_repository.dart';

class GetNearbyStationsUseCase implements UseCase<List<ChargingStation>, GeoPoint> {
  final StationRepository _repository;
  const GetNearbyStationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChargingStation>>> call(GeoPoint origin) =>
      _repository.getStations(origin);
}

class StationDetailParams extends Equatable {
  final String id;
  final GeoPoint? origin;
  const StationDetailParams(this.id, {this.origin});
  @override
  List<Object?> get props => [id, origin?.latitude, origin?.longitude];
}

class GetStationDetailsUseCase
    implements UseCase<ChargingStation, StationDetailParams> {
  final StationRepository _repository;
  const GetStationDetailsUseCase(this._repository);

  @override
  Future<Either<Failure, ChargingStation>> call(StationDetailParams p) =>
      _repository.getStationById(p.id, origin: p.origin);
}

class GetFavouriteStationsUseCase implements UseCase<Set<String>, NoParams> {
  final StationRepository _repository;
  const GetFavouriteStationsUseCase(this._repository);

  @override
  Future<Either<Failure, Set<String>>> call(NoParams params) =>
      _repository.getFavouriteIds();
}

class ToggleFavouriteStationUseCase implements UseCase<Set<String>, String> {
  final StationRepository _repository;
  const ToggleFavouriteStationUseCase(this._repository);

  @override
  Future<Either<Failure, Set<String>>> call(String stationId) =>
      _repository.toggleFavourite(stationId);
}

/// Pure business logic: search text + filter criteria + sort order.
///
/// Kept synchronous and side-effect free so it is trivially unit-testable.
class FilterStationsUseCase {
  const FilterStationsUseCase();

  List<ChargingStation> call(
    List<ChargingStation> stations, {
    String query = '',
    StationFilter filter = StationFilter.none,
  }) {
    final q = query.trim().toLowerCase();
    final result = stations.where((s) {
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !s.city.toLowerCase().contains(q) &&
          !s.address.toLowerCase().contains(q) &&
          !s.network.toLowerCase().contains(q)) {
        return false;
      }
      return filter.matches(s);
    }).toList();

    switch (filter.sort) {
      case StationSort.distance:
        result.sort((a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity));
      case StationSort.power:
        result.sort((a, b) => b.maxPowerKw.compareTo(a.maxPowerKw));
      case StationSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }
}
