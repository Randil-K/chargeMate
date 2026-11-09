import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';
import 'package:charge_mate/features/explore/domain/usecases/explore_usecases.dart';

enum ExploreStatus { initial, loading, ready, failure }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final List<NearbyPlace> allPlaces;
  final List<NearbyPlace> visiblePlaces;
  final PlaceCategory selectedCategory;
  final int chargingMinutes;
  final bool strictTimeFit;
  final String activityBanner;
  final String? error;

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.allPlaces = const [],
    this.visiblePlaces = const [],
    this.selectedCategory = PlaceCategory.all,
    this.chargingMinutes = 35,
    this.strictTimeFit = false,
    this.activityBanner = '',
    this.error,
  });

  int get fittingCount =>
      allPlaces.where((p) => p.fitsInTimeBudget(chargingMinutes)).length;

  ExploreState copyWith({
    ExploreStatus? status,
    List<NearbyPlace>? allPlaces,
    List<NearbyPlace>? visiblePlaces,
    PlaceCategory? selectedCategory,
    int? chargingMinutes,
    bool? strictTimeFit,
    String? activityBanner,
    String? error,
  }) =>
      ExploreState(
        status: status ?? this.status,
        allPlaces: allPlaces ?? this.allPlaces,
        visiblePlaces: visiblePlaces ?? this.visiblePlaces,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        chargingMinutes: chargingMinutes ?? this.chargingMinutes,
        strictTimeFit: strictTimeFit ?? this.strictTimeFit,
        activityBanner: activityBanner ?? this.activityBanner,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [
        status,
        allPlaces,
        visiblePlaces,
        selectedCategory,
        chargingMinutes,
        strictTimeFit,
        activityBanner,
        error,
      ];
}

class ExploreCubit extends Cubit<ExploreState> {
  final GetPlacesNearStationUseCase _getPlaces;
  final RecommendPlacesByTimeUseCase _recommend;

  ExploreCubit({
    required GetPlacesNearStationUseCase getPlaces,
    RecommendPlacesByTimeUseCase recommend =
        const RecommendPlacesByTimeUseCase(),
    int initialChargingMinutes = 35,
  })  : _getPlaces = getPlaces,
        _recommend = recommend,
        super(ExploreState(
          chargingMinutes: initialChargingMinutes,
          activityBanner:
              recommend.activityBannerForMinutes(initialChargingMinutes),
        ));

  Future<void> loadPlaces({
    required String stationId,
    required double stationLat,
    required double stationLng,
  }) async {
    emit(state.copyWith(status: ExploreStatus.loading));
    final result = await _getPlaces(StationPlacesParams(
      stationId: stationId,
      stationLat: stationLat,
      stationLng: stationLng,
    ));

    result.fold(
      (f) => emit(
          state.copyWith(status: ExploreStatus.failure, error: f.message)),
      (places) => emit(_recompute(state.copyWith(
        status: ExploreStatus.ready,
        allPlaces: places,
      ))),
    );
  }

  void selectCategory(PlaceCategory category) {
    emit(_recompute(state.copyWith(selectedCategory: category)));
  }

  void setChargingMinutes(int minutes) {
    emit(_recompute(state.copyWith(
      chargingMinutes: minutes,
      activityBanner: _recommend.activityBannerForMinutes(minutes),
    )));
  }

  void toggleStrictTimeFit(bool value) {
    emit(_recompute(state.copyWith(strictTimeFit: value)));
  }

  ExploreState _recompute(ExploreState s) {
    final visible = _recommend(
      s.allPlaces,
      category: s.selectedCategory,
      chargingMinutes: s.chargingMinutes,
      strictTimeFit: s.strictTimeFit,
    );
    return s.copyWith(visiblePlaces: visible);
  }
}
