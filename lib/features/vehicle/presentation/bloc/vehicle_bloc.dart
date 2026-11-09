import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/vehicle_usecases.dart';

// ═════════════════════════════════ EVENTS ═════════════════════════════
sealed class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

class VehiclesRequested extends VehicleEvent {
  const VehiclesRequested();
}

class VehicleAdded extends VehicleEvent {
  final Vehicle vehicle;
  const VehicleAdded(this.vehicle);
  @override
  List<Object?> get props => [vehicle];
}

class VehicleUpdated extends VehicleEvent {
  final Vehicle vehicle;
  const VehicleUpdated(this.vehicle);
  @override
  List<Object?> get props => [vehicle];
}

class VehicleDeleted extends VehicleEvent {
  final String id;
  const VehicleDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class PrimaryVehicleSet extends VehicleEvent {
  final String id;
  const PrimaryVehicleSet(this.id);
  @override
  List<Object?> get props => [id];
}

// ═════════════════════════════════ STATE ══════════════════════════════
enum VehicleStatus { initial, loading, ready, failure }

class VehicleState extends Equatable {
  final VehicleStatus status;
  final List<Vehicle> vehicles;
  final List<VehicleSpec> catalog;
  final String? error;

  /// Incremented on every successful save so screens can react (e.g. pop).
  final int saveCount;

  const VehicleState({
    this.status = VehicleStatus.initial,
    this.vehicles = const [],
    this.catalog = const [],
    this.error,
    this.saveCount = 0,
  });

  Vehicle? get primary {
    for (final v in vehicles) {
      if (v.isPrimary) return v;
    }
    return vehicles.isEmpty ? null : vehicles.first;
  }

  Vehicle? byId(String id) {
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  VehicleState copyWith({
    VehicleStatus? status,
    List<Vehicle>? vehicles,
    List<VehicleSpec>? catalog,
    String? error,
    bool clearError = false,
    int? saveCount,
  }) =>
      VehicleState(
        status: status ?? this.status,
        vehicles: vehicles ?? this.vehicles,
        catalog: catalog ?? this.catalog,
        error: clearError ? null : (error ?? this.error),
        saveCount: saveCount ?? this.saveCount,
      );

  @override
  List<Object?> get props => [status, vehicles, catalog, error, saveCount];
}

// ═════════════════════════════════ BLOC ═══════════════════════════════
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetVehiclesUseCase _get;
  final AddVehicleUseCase _add;
  final UpdateVehicleUseCase _update;
  final DeleteVehicleUseCase _delete;
  final SetPrimaryVehicleUseCase _setPrimary;
  final GetVehicleSpecsUseCase _specs;

  VehicleBloc({
    required GetVehiclesUseCase get,
    required AddVehicleUseCase add,
    required UpdateVehicleUseCase update,
    required DeleteVehicleUseCase delete,
    required SetPrimaryVehicleUseCase setPrimary,
    required GetVehicleSpecsUseCase specs,
  })  : _get = get,
        _add = add,
        _update = update,
        _delete = delete,
        _setPrimary = setPrimary,
        _specs = specs,
        super(const VehicleState()) {
    on<VehiclesRequested>(_onLoad);
    on<VehicleAdded>((e, emit) => _mutate(emit, () => _add(e.vehicle), save: true));
    on<VehicleUpdated>(
        (e, emit) => _mutate(emit, () => _update(e.vehicle), save: true));
    on<VehicleDeleted>((e, emit) => _mutate(emit, () => _delete(e.id)));
    on<PrimaryVehicleSet>((e, emit) => _mutate(emit, () => _setPrimary(e.id)));
  }

  Future<void> _onLoad(VehiclesRequested e, Emitter<VehicleState> emit) async {
    emit(state.copyWith(status: VehicleStatus.loading, clearError: true));
    final vehicles = await _get(const NoParams());
    final catalog = await _specs(const NoParams());
    vehicles.fold(
      (f) => emit(state.copyWith(status: VehicleStatus.failure, error: f.message)),
      (list) => emit(state.copyWith(
        status: VehicleStatus.ready,
        vehicles: list,
        catalog: catalog.getOrElse(() => const []),
      )),
    );
  }

  Future<void> _mutate(
    Emitter<VehicleState> emit,
    Future<dynamic> Function() op, {
    bool save = false,
  }) async {
    final result = await op();
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (list) => emit(state.copyWith(
        status: VehicleStatus.ready,
        vehicles: list as List<Vehicle>,
        clearError: true,
        saveCount: save ? state.saveCount + 1 : state.saveCount,
      )),
    );
  }
}
