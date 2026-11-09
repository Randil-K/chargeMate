import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/core/usecases/usecase.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/domain/repositories/vehicle_repository.dart';

class GetVehiclesUseCase implements UseCase<List<Vehicle>, NoParams> {
  final VehicleRepository _repo;
  const GetVehiclesUseCase(this._repo);
  @override
  Future<Either<Failure, List<Vehicle>>> call(NoParams p) => _repo.getVehicles();
}

class AddVehicleUseCase implements UseCase<List<Vehicle>, Vehicle> {
  final VehicleRepository _repo;
  const AddVehicleUseCase(this._repo);

  @override
  Future<Either<Failure, List<Vehicle>>> call(Vehicle v) async {
    if (v.connectors.isEmpty) {
      return const Left(ValidationFailure(
          message: 'Select at least one supported connector.'));
    }
    if (v.batteryKwh <= 0 || v.rangeKm <= 0) {
      return const Left(
          ValidationFailure(message: 'Battery and range must be positive.'));
    }
    return _repo.addVehicle(v);
  }
}

class UpdateVehicleUseCase implements UseCase<List<Vehicle>, Vehicle> {
  final VehicleRepository _repo;
  const UpdateVehicleUseCase(this._repo);
  @override
  Future<Either<Failure, List<Vehicle>>> call(Vehicle v) =>
      _repo.updateVehicle(v);
}

class DeleteVehicleUseCase implements UseCase<List<Vehicle>, String> {
  final VehicleRepository _repo;
  const DeleteVehicleUseCase(this._repo);
  @override
  Future<Either<Failure, List<Vehicle>>> call(String id) =>
      _repo.deleteVehicle(id);
}

class SetPrimaryVehicleUseCase implements UseCase<List<Vehicle>, String> {
  final VehicleRepository _repo;
  const SetPrimaryVehicleUseCase(this._repo);
  @override
  Future<Either<Failure, List<Vehicle>>> call(String id) =>
      _repo.setPrimary(id);
}

class GetVehicleSpecsUseCase implements UseCase<List<VehicleSpec>, NoParams> {
  final VehicleRepository _repo;
  const GetVehicleSpecsUseCase(this._repo);
  @override
  Future<Either<Failure, List<VehicleSpec>>> call(NoParams p) =>
      _repo.getSpecCatalog();
}
