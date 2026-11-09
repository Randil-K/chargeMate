import 'package:equatable/equatable.dart';

/// Community/operator-reported operational state of a station.
enum StationStatus {
  operational('Operational'),
  issuesReported('Issues reported'),
  offline('Offline'),
  unknown('Status unknown');

  final String label;
  const StationStatus(this.label);
}

/// Live status of an individual charging point.
enum PointStatus {
  available('Available'),
  inUse('In use'),
  outOfService('Out of service'),
  unknown('Unknown');

  final String label;
  const PointStatus(this.label);
}

/// A single plug at a station.
class ChargingPoint extends Equatable {
  final String id;
  final String connectorType; // CCS2, CHAdeMO, Type 2, Type 1, GB/T
  final String chargingType; // AC or DC
  final double powerKw;
  final PointStatus status;
  final double? pricePerKwh; // LKR

  const ChargingPoint({
    required this.id,
    required this.connectorType,
    required this.chargingType,
    required this.powerKw,
    required this.status,
    this.pricePerKwh,
  });

  bool get isDc => chargingType.toUpperCase() == 'DC';

  @override
  List<Object?> get props =>
      [id, connectorType, chargingType, powerKw, status, pricePerKwh];
}

/// A public EV charging location.
class ChargingStation extends Equatable {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String operatorName;
  final String network;
  final String openingHours;
  final String contactNumber;
  final StationStatus status;
  final DateTime lastVerified;
  final double rating;
  final int reviewCount;
  final List<String> amenities;
  final List<ChargingPoint> points;

  /// Distance from the user, filled in by the repository. `null` if unknown.
  final double? distanceKm;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.operatorName,
    required this.network,
    required this.openingHours,
    required this.contactNumber,
    required this.status,
    required this.lastVerified,
    required this.rating,
    required this.reviewCount,
    required this.amenities,
    required this.points,
    this.distanceKm,
  });

  // ── Derived values ────────────────────────────────────────────────
  double get maxPowerKw => points.isEmpty
      ? 0
      : points.map((p) => p.powerKw).reduce((a, b) => a > b ? a : b);

  Set<String> get connectorTypes => points.map((p) => p.connectorType).toSet();

  int get availableCount =>
      points.where((p) => p.status == PointStatus.available).length;

  bool get hasDcFast => points.any((p) => p.isDc);

  bool get is24Hours => openingHours.toLowerCase().contains('24');

  double? get minPrice {
    final prices = points.map((p) => p.pricePerKwh).whereType<double>();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  /// Whether at least one point accepts one of the given connectors.
  bool supportsAny(Iterable<String> connectors) =>
      connectorTypes.any(connectors.contains);

  ChargingStation copyWith({
    double? distanceKm,
    StationStatus? status,
    DateTime? lastVerified,
    double? rating,
    int? reviewCount,
  }) =>
      ChargingStation(
        id: id,
        name: name,
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
        operatorName: operatorName,
        network: network,
        openingHours: openingHours,
        contactNumber: contactNumber,
        status: status ?? this.status,
        lastVerified: lastVerified ?? this.lastVerified,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        amenities: amenities,
        points: points,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  @override
  List<Object?> get props =>
      [id, status, lastVerified, rating, reviewCount, points, distanceKm];
}
