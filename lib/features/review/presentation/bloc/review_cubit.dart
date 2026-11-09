import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/features/review/domain/entities/station_review.dart';
import 'package:charge_mate/features/review/domain/usecases/review_usecases.dart';

enum ReviewLoadStatus { initial, loading, ready, failure }

class ReviewState extends Equatable {
  final ReviewLoadStatus status;
  final List<StationReview> reviews;
  final String? error;

  const ReviewState({
    this.status = ReviewLoadStatus.initial,
    this.reviews = const [],
    this.error,
  });

  ReviewState copyWith({
    ReviewLoadStatus? status,
    List<StationReview>? reviews,
    String? error,
  }) =>
      ReviewState(
        status: status ?? this.status,
        reviews: reviews ?? this.reviews,
        error: error,
      );

  @override
  List<Object?> get props => [status, reviews, error];
}

class ReviewCubit extends Cubit<ReviewState> {
  final GetStationReviewsUseCase _getReviews;
  final SubmitStationReviewUseCase _submitReview;

  ReviewCubit({
    required GetStationReviewsUseCase getReviews,
    required SubmitStationReviewUseCase submitReview,
  })  : _getReviews = getReviews,
        _submitReview = submitReview,
        super(const ReviewState());

  Future<void> load(String stationId) async {
    emit(state.copyWith(status: ReviewLoadStatus.loading));
    final result = await _getReviews(stationId);
    result.fold(
      (f) => emit(
          state.copyWith(status: ReviewLoadStatus.failure, error: f.message)),
      (list) => emit(
          state.copyWith(status: ReviewLoadStatus.ready, reviews: list)),
    );
  }

  Future<bool> submit(StationReview review) async {
    final result = await _submitReview(review);
    return result.fold(
      (_) => false,
      (saved) {
        emit(state.copyWith(
          status: ReviewLoadStatus.ready,
          reviews: [saved, ...state.reviews],
        ));
        return true;
      },
    );
  }
}
