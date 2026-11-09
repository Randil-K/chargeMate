import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/core/services/location_service.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/domain/entities/station_filter.dart';
import 'package:charge_mate/features/station/domain/usecases/station_usecases.dart';

// ═════════════════════════════════ EVENTS ═════════════════════════════
sealed class StationsEvent extends Equatable {
  const StationsEvent();
  @override
  List<Object?> get props => [];
}

/// Loads stations around the user's location.
class StationsRequested extends StationsEvent {
  const StationsRequested();
}

class StationSearchChanged extends StationsEvent {
  final String query;
  const StationSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class StationFilterChanged extends StationsEvent {
  final StationFilter filter;
  const StationFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class FavouriteToggled extends StationsEvent {
  final String stationId;
  const FavouriteToggled(this.stationId);
  @override
  List<Object?> get props => [stationId];
}

class CompatibleOnlyToggled extends StationsEvent {
  final bool value;
  const CompatibleOnlyToggled(this.value);
  @override
  List<Object?> get props => [value];
}

/// Pushed whenever the user's primary vehicle changes.
class VehicleConnectorsChanged extends StationsEvent {
  final Set<String> connectors;
  final String? vehicleName;
  const VehicleConnectorsChanged(this.connectors, this.vehicleName);
  @override
  List<Object?> get props => [connectors, vehicleName];
}

/// Community status report or new review rating update for a station.
class StationStatusUpdated extends StationsEvent {
  final String stationId;
  final StationStatus? newStatus;
  final double? newRating;
  const StationStatusUpdated({
    required this.stationId,
    this.newStatus,
    this.newRating,
  });
  @override
  List<Object?> get props => [stationId, newStatus, newRating];
}

// ═════════════════════════════════ STATE ══════════════════════════════
enum StationsStatus { initial, loading, ready, failure }

class StationsState extends Equatable {
  final StationsStatus status;
  final List<ChargingStation> all;
  final List<ChargingStation> visible;
  final String query;
  final StationFilter filter;
  final Set<String> favourites;
  final GeoPoint origin;
  final String? locationNotice;
  final bool compatibleOnly;
  final Set<String> vehicleConnectors;
  final String? vehicleName;
  final String? error;

  const StationsState({
    this.status = StationsStatus.initial,
    this.all = const [],
    this.visible = const [],
    this.query = '',
    this.filter = StationFilter.none,
    this.favourites = const {},
    this.origin = GeoPoint.colombo,
    this.locationNotice,
    this.compatibleOnly = false,
    this.vehicleConnectors = const {},
    this.vehicleName,
    this.error,
  });

  bool get hasVehicle => vehicleConnectors.isNotEmpty;

  bool isCompatible(ChargingStation s) =>
      !hasVehicle || s.supportsAny(vehicleConnectors);

  List<ChargingStation> get favouriteStations =>
      all.where((s) => favourites.contains(s.id)).toList();

  ChargingStation? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  StationsState copyWith({
    StationsStatus? status,
    List<ChargingStation>? all,
    List<ChargingStation>? visible,
    String? query,
    StationFilter? filter,
    Set<String>? favourites,
    GeoPoint? origin,
    String? locationNotice,
    bool clearNotice = false,
    bool? compatibleOnly,
    Set<String>? vehicleConnectors,
    String? vehicleName,
    String? error,
  }) =>
      StationsState(
        status: status ?? this.status,
        all: all ?? this.all,
        visible: visible ?? this.visible,
        query: query ?? this.query,
        filter: filter ?? this.filter,
        favourites: favourites ?? this.favourites,
        origin: origin ?? this.origin,
        locationNotice:
            clearNotice ? null : (locationNotice ?? this.locationNotice),
        compatibleOnly: compatibleOnly ?? this.compatibleOnly,
        vehicleConnectors: vehicleConnectors ?? this.vehicleConnectors,
        vehicleName: vehicleName ?? this.vehicleName,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [
        status,
        all,
        visible,
        query,
        filter,
        favourites,
        origin.latitude,
        origin.longitude,
        locationNotice,
        compatibleOnly,
        vehicleConnectors,
        vehicleName,
        error,
      ];
}

// ═════════════════════════════════ BLOC ═══════════════════════════════
class StationsBloc extends Bloc<StationsEvent, StationsState> {
  final LocationService _location;
  final GetNearbyStationsUseCase _getNearby;
  final GetFavouriteStationsUseCase _getFavourites;
  final ToggleFavouriteStationUseCase _toggleFavourite;
  final FilterStationsUseCase _filter;

  StationsBloc({
    required LocationService location,
    required GetNearbyStationsUseCase getNearby,
    required GetFavouriteStationsUseCase getFavourites,
    required ToggleFavouriteStationUseCase toggleFavourite,
    FilterStationsUseCase filter = const FilterStationsUseCase(),
  })  : _location = location,
        _getNearby = getNearby,
        _getFavourites = getFavourites,
        _toggleFavourite = toggleFavourite,
        _filter = filter,
        super(const StationsState()) {
    on<StationsRequested>(_onRequested);
    on<StationSearchChanged>(
        (e, emit) => emit(_recompute(state.copyWith(query: e.query))));
    on<StationFilterChanged>(
        (e, emit) => emit(_recompute(state.copyWith(filter: e.filter))));
    on<CompatibleOnlyToggled>(
        (e, emit) => emit(_recompute(state.copyWith(compatibleOnly: e.value))));
    on<VehicleConnectorsChanged>((e, emit) => emit(_recompute(state.copyWith(
          vehicleConnectors: e.connectors,
          vehicleName: e.vehicleName,
          compatibleOnly: e.connectors.isEmpty ? false : state.compatibleOnly,
        ))));
    on<FavouriteToggled>(_onFavourite);
    on<StationStatusUpdated>(_onStatusUpdated);
  }

  void _onStatusUpdated(
      StationStatusUpdated e, Emitter<StationsState> emit) {
    final updatedAll = state.all.map((s) {
      if (s.id != e.stationId) return s;
      final newCount = e.newRating != null ? s.reviewCount + 1 : s.reviewCount;
      final avgRating = e.newRating != null
          ? double.parse(
              (((s.rating * s.reviewCount) + e.newRating!) / newCount)
                  .toStringAsFixed(1),
            )
          : s.rating;
      return s.copyWith(
        status: e.newStatus ?? s.status,
        lastVerified: DateTime.now(),
        rating: avgRating,
        reviewCount: newCount,
      );
    }).toList();
    emit(_recompute(state.copyWith(all: updatedAll)));
  }

  StationsState _recompute(StationsState s) {
    var effective = s.filter;
    if (s.compatibleOnly && s.hasVehicle) {
      final connectors = s.filter.connectorTypes.isEmpty
          ? s.vehicleConnectors
          : s.filter.connectorTypes.intersection(s.vehicleConnectors);
      effective = s.filter.copyWith(
          connectorTypes: connectors.isEmpty ? {'__none__'} : connectors);
    }
    return s.copyWith(
        visible: _filter(s.all, query: s.query, filter: effective));
  }

  Future<void> _onRequested(
      StationsRequested e, Emitter<StationsState> emit) async {
    // 1. Show loading only if we have zero stations loaded yet
    if (state.all.isEmpty) {
      emit(state.copyWith(status: StationsStatus.loading));
    }

    // 2. Load cached stations and favourites immediately using lastKnown point (Colombo by default)
    // This completes in milliseconds so the UI renders immediately without waiting!
    final favs = await _getFavourites(const NoParams());
    final initialResult = await _getNearby(_location.lastKnown);

    initialResult.fold(
      (f) {
        if (state.all.isEmpty) {
          emit(state.copyWith(status: StationsStatus.failure, error: f.message));
        }
      },
      (stations) {
        emit(_recompute(state.copyWith(
          status: StationsStatus.ready,
          all: stations,
          origin: _location.lastKnown,
          favourites: favs.getOrElse(() => const {}),
        )));
      },
    );

    // 3. Asynchronously fetch fresh GPS location without blocking the initial screen render
    try {
      final loc = await _location.getCurrentLocation();
      if (loc.point.latitude != state.origin.latitude ||
          loc.point.longitude != state.origin.longitude ||
          loc.message != state.locationNotice) {
        final updatedResult = await _getNearby(loc.point);
        updatedResult.fold(
          (_) => null,
          (updatedStations) {
            emit(_recompute(state.copyWith(
              all: updatedStations,
              origin: loc.point,
              locationNotice: loc.message,
              clearNotice: loc.message == null,
            )));
          },
        );
      }
    } catch (_) {
      // Non-critical: Colombo stations are already displayed
    }
  }

  Future<void> _onFavourite(
      FavouriteToggled e, Emitter<StationsState> emit) async {
    final previous = state.favourites;
    final optimistic = {...previous};
    if (!optimistic.remove(e.stationId)) optimistic.add(e.stationId);
    emit(state.copyWith(favourites: optimistic));

    final result = await _toggleFavourite(e.stationId);
    result.fold(
      (_) => emit(state.copyWith(favourites: previous)),
      (favs) => emit(state.copyWith(favourites: favs)),
    );
  }
}
