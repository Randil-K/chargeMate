import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/review/domain/entities/station_review.dart';
import 'package:charge_mate/features/review/domain/repositories/review_repository.dart';

class GetStationReviewsUseCase
    implements UseCase<List<StationReview>, String> {
  final ReviewRepository _repo;
  const GetStationReviewsUseCase(this._repo);

  @override
  Future<Either<Failure, List<StationReview>>> call(String stationId) =>
      _repo.getReviewsForStation(stationId);
}

class SubmitStationReviewUseCase
    implements UseCase<StationReview, StationReview> {
  final ReviewRepository _repo;
  const SubmitStationReviewUseCase(this._repo);

  @override
  Future<Either<Failure, StationReview>> call(StationReview review) =>
      _repo.submitReview(review);
}
