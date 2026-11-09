import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';

/// Contract for Module 4 (Charge & Explore) data operations.
abstract class ExploreRepository {
  Future<Either<Failure, List<NearbyPlace>>> getPlacesNearStation({
    required String stationId,
    required double stationLat,
    required double stationLng,
  });
}
