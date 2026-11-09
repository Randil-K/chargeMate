import 'package:equatable/equatable.dart';

/// A connector the vehicle can accept, with its max charge rate.
class VehicleConnector extends Equatable {
  final String type;
  final double maxKw;

  const VehicleConnector({required this.type, required this.maxKw});

  @override
  List<Object?> get props => [type, maxKw];
}

/// Verified manufacturer specification used to auto-fill vehicle details.
class VehicleSpec extends Equatable {
  final String specId;
  final String manufacturer;
  final String model;
  final int fromYear;
  final int toYear;
  final double batteryKwh;
  final int rangeKm;
  final List<VehicleConnector> connectors;
  final double maxAcKw;
  final double maxDcKw;

  const VehicleSpec({
    required this.specId,
    required this.manufacturer,
    required this.model,
    required this.fromYear,
    required this.toYear,
    required this.batteryKwh,
    required this.rangeKm,
    required this.connectors,
    required this.maxAcKw,
    required this.maxDcKw,
  });

  String get displayName => '$manufacturer $model';

  @override
  List<Object?> get props => [specId];
}

/// A vehicle registered by the user.
class Vehicle extends Equatable {
  final String id;
  final String manufacturer;
  final String model;
  final int year;
  final String? nickname;
  final double batteryKwh;
  final int rangeKm;
  final List<VehicleConnector> connectors;
  final double maxAcKw;
  final double maxDcKw;
  final bool isPrimary;

  /// The catalog spec this vehicle was created from (null if entered manually).
  final String? specId;

  const Vehicle({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.year,
    this.nickname,
    required this.batteryKwh,
    required this.rangeKm,
    required this.connectors,
    required this.maxAcKw,
    required this.maxDcKw,
    this.isPrimary = false,
    this.specId,
  });

  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : '$manufacturer $model';

  Set<String> get connectorTypes => connectors.map((c) => c.type).toSet();

  bool get isVerifiedSpec => specId != null;

  /// Highest rate the vehicle accepts on the given connector, or 0.
  double maxKwFor(String connectorType) => connectors
      .where((c) => c.type == connectorType)
      .fold(0.0, (m, c) => c.maxKw > m ? c.maxKw : m);

  Vehicle copyWith({
    String? id,
    String? manufacturer,
    String? model,
    int? year,
    String? nickname,
    double? batteryKwh,
    int? rangeKm,
    List<VehicleConnector>? connectors,
    double? maxAcKw,
    double? maxDcKw,
    bool? isPrimary,
    String? specId,
  }) =>
      Vehicle(
        id: id ?? this.id,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
        year: year ?? this.year,
        nickname: nickname ?? this.nickname,
        batteryKwh: batteryKwh ?? this.batteryKwh,
        rangeKm: rangeKm ?? this.rangeKm,
        connectors: connectors ?? this.connectors,
        maxAcKw: maxAcKw ?? this.maxAcKw,
        maxDcKw: maxDcKw ?? this.maxDcKw,
        isPrimary: isPrimary ?? this.isPrimary,
        specId: specId ?? this.specId,
      );

  @override
  List<Object?> get props => [
        id,
        manufacturer,
        model,
        year,
        nickname,
        batteryKwh,
        rangeKm,
        connectors,
        maxAcKw,
        maxDcKw,
        isPrimary,
        specId,
      ];
}
