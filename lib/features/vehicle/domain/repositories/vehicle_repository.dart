import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';

/// Contract for vehicle management (mirrors `/api/vehicles`).
abstract class VehicleRepository {
  Future<Either<Failure, List<Vehicle>>> getVehicles();
  Future<Either<Failure, List<Vehicle>>> addVehicle(Vehicle vehicle);
  Future<Either<Failure, List<Vehicle>>> updateVehicle(Vehicle vehicle);
  Future<Either<Failure, List<Vehicle>>> deleteVehicle(String id);
  Future<Either<Failure, List<Vehicle>>> setPrimary(String id);

  /// Catalog of verified manufacturer specs for auto-fill.
  Future<Either<Failure, List<VehicleSpec>>> getSpecCatalog();
}
