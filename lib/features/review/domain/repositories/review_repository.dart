import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/review/domain/entities/station_review.dart';

abstract class ReviewRepository {
  Future<Either<Failure, List<StationReview>>> getReviewsForStation(
    String stationId,
  );

  Future<Either<Failure, StationReview>> submitReview(StationReview review);
}
