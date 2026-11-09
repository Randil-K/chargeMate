import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';

class VehicleConnectorModel extends VehicleConnector {
  const VehicleConnectorModel({required super.type, required super.maxKw});

  factory VehicleConnectorModel.fromJson(Map<String, dynamic> j) =>
      VehicleConnectorModel(
        type: j['type'] as String,
        maxKw: (j['maxKw'] as num).toDouble(),
      );

  static Map<String, dynamic> toJson(VehicleConnector c) =>
      {'type': c.type, 'maxKw': c.maxKw};
}

class VehicleSpecModel extends VehicleSpec {
  const VehicleSpecModel({
    required super.specId,
    required super.manufacturer,
    required super.model,
    required super.fromYear,
    required super.toYear,
    required super.batteryKwh,
    required super.rangeKm,
    required super.connectors,
    required super.maxAcKw,
    required super.maxDcKw,
  });

  factory VehicleSpecModel.fromJson(Map<String, dynamic> j) {
    final years = (j['years'] as List).cast<int>();
    return VehicleSpecModel(
      specId: j['specId'] as String,
      manufacturer: j['manufacturer'] as String,
      model: j['model'] as String,
      fromYear: years.first,
      toYear: years.last,
      batteryKwh: (j['batteryKwh'] as num).toDouble(),
      rangeKm: j['rangeKm'] as int,
      connectors: (j['connectors'] as List)
          .map((e) => VehicleConnectorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxAcKw: (j['maxAcKw'] as num).toDouble(),
      maxDcKw: (j['maxDcKw'] as num).toDouble(),
    );
  }
}

class VehicleModel {
  static Vehicle fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['vehicleId'] as String,
        manufacturer: j['manufacturer'] as String,
        model: j['model'] as String,
        year: j['year'] as int,
        nickname: j['nickname'] as String?,
        batteryKwh: (j['batteryCapacity'] as num).toDouble(),
        rangeKm: j['estimatedRange'] as int,
        connectors: (j['connectors'] as List)
            .map((e) =>
                VehicleConnectorModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        maxAcKw: (j['maxAcKw'] as num).toDouble(),
        maxDcKw: (j['maxDcKw'] as num).toDouble(),
        isPrimary: j['isPrimary'] as bool? ?? false,
        specId: j['specId'] as String?,
      );

  static Map<String, dynamic> toJson(Vehicle v) => {
        'vehicleId': v.id,
        'manufacturer': v.manufacturer,
        'model': v.model,
        'year': v.year,
        'nickname': v.nickname,
        'batteryCapacity': v.batteryKwh,
        'estimatedRange': v.rangeKm,
        'connectors': v.connectors.map(VehicleConnectorModel.toJson).toList(),
        'maxAcKw': v.maxAcKw,
        'maxDcKw': v.maxDcKw,
        'isPrimary': v.isPrimary,
        'specId': v.specId,
      };
}
