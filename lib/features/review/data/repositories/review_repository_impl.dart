import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/review/data/datasources/review_remote_datasource.dart';
import 'package:charge_mate/features/review/domain/entities/station_review.dart';
import 'package:charge_mate/features/review/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource _remote;
  const ReviewRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<StationReview>>> getReviewsForStation(
    String stationId,
  ) async {
    try {
      final list = await _remote.getReviewsForStation(stationId);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StationReview>> submitReview(
    StationReview review,
  ) async {
    try {
      final saved = await _remote.submitReview(review);
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
