import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

/// JSON mapping for [ChargingPoint] (Spring Boot `ChargingPointDTO`).
class ChargingPointModel extends ChargingPoint {
  const ChargingPointModel({
    required super.id,
    required super.connectorType,
    required super.chargingType,
    required super.powerKw,
    required super.status,
    super.pricePerKwh,
  });

  factory ChargingPointModel.fromJson(Map<String, dynamic> json) =>
      ChargingPointModel(
        id: json['id'] as String,
        connectorType: json['connectorType'] as String,
        chargingType: json['chargingType'] as String,
        powerKw: (json['powerKw'] as num).toDouble(),
        status: _pointStatus(json['status'] as String?),
        pricePerKwh: (json['pricePerKwh'] as num?)?.toDouble(),
      );

  static PointStatus _pointStatus(String? raw) => switch (raw) {
        'AVAILABLE' => PointStatus.available,
        'IN_USE' => PointStatus.inUse,
        'OUT_OF_SERVICE' => PointStatus.outOfService,
        _ => PointStatus.unknown,
      };
}

/// JSON mapping for [ChargingStation] (Spring Boot `StationDTO`).
class ChargingStationModel extends ChargingStation {
  const ChargingStationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.city,
    required super.latitude,
    required super.longitude,
    required super.operatorName,
    required super.network,
    required super.openingHours,
    required super.contactNumber,
    required super.status,
    required super.lastVerified,
    required super.rating,
    required super.reviewCount,
    required super.amenities,
    required super.points,
  });

  factory ChargingStationModel.fromJson(Map<String, dynamic> json) =>
      ChargingStationModel(
        id: json['stationId'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        operatorName: json['operatorName'] as String,
        network: json['network'] as String,
        openingHours: json['openingHours'] as String,
        contactNumber: json['contactNumber'] as String,
        status: _stationStatus(json['reportedStatus'] as String?),
        lastVerified: DateTime.parse(json['lastVerifiedDate'] as String),
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        amenities: (json['amenities'] as List).cast<String>(),
        points: (json['chargingPoints'] as List)
            .map((e) => ChargingPointModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static StationStatus _stationStatus(String? raw) => switch (raw) {
        'OPERATIONAL' => StationStatus.operational,
        'ISSUES_REPORTED' => StationStatus.issuesReported,
        'OFFLINE' => StationStatus.offline,
        _ => StationStatus.unknown,
      };
}
