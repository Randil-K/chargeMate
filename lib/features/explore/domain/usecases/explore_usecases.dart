import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';
import 'package:charge_mate/features/explore/domain/repositories/explore_repository.dart';

class StationPlacesParams extends Equatable {
  final String stationId;
  final double stationLat;
  final double stationLng;

  const StationPlacesParams({
    required this.stationId,
    required this.stationLat,
    required this.stationLng,
  });

  @override
  List<Object?> get props => [stationId, stationLat, stationLng];
}

class GetPlacesNearStationUseCase
    implements UseCase<List<NearbyPlace>, StationPlacesParams> {
  final ExploreRepository _repository;
  const GetPlacesNearStationUseCase(this._repository);

  @override
  Future<Either<Failure, List<NearbyPlace>>> call(StationPlacesParams params) =>
      _repository.getPlacesNearStation(
        stationId: params.stationId,
        stationLat: params.stationLat,
        stationLng: params.stationLng,
      );
}

/// Pure domain service that filters & ranks nearby places based on:
/// - Selected category
/// - Estimated charging duration (round-trip walk + activity time)
/// - Whether the user wants only time-compatible recommendations
class RecommendPlacesByTimeUseCase {
  const RecommendPlacesByTimeUseCase();

  List<NearbyPlace> call(
    List<NearbyPlace> places, {
    PlaceCategory category = PlaceCategory.all,
    required int chargingMinutes,
    bool strictTimeFit = false,
  }) {
    final filtered = places.where((p) {
      if (category != PlaceCategory.all && p.category != category) {
        return false;
      }
      if (strictTimeFit && !p.fitsInTimeBudget(chargingMinutes)) {
        return false;
      }
      return true;
    }).toList();

    // Sort places that fit the charging window first, then by walking distance.
    filtered.sort((a, b) {
      final aFits = a.fitsInTimeBudget(chargingMinutes);
      final bFits = b.fitsInTimeBudget(chargingMinutes);
      if (aFits != bFits) return aFits ? -1 : 1;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    return filtered;
  }

  /// Returns a human-readable activity suggestion banner for the given time window.
  String activityBannerForMinutes(int minutes) {
    if (minutes <= 15) {
      return 'Quick Stop (10–15 min): Best for coffee grab-and-go, bakeries & convenience stores.';
    }
    if (minutes <= 30) {
      return 'Short Break (20–30 min): Ideal for sit-down cafés, bakeries & quick supermarket runs.';
    }
    if (minutes <= 45) {
      return 'Medium Break (30–45 min): Great for casual dining, parks & shopping.';
    }
    if (minutes <= 60) {
      return 'Full Session (45–60 min): Enough time for restaurants, temples & scenic walks.';
    }
    return 'Extended Charge (60+ min): Explore tourist attractions, malls or catch a movie.';
  }
}
