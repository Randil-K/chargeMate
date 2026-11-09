import 'package:equatable/equatable.dart';

/// Categories defined in Module 4 (Charge & Explore) of the proposal.
enum PlaceCategory {
  all('All', 'ALL'),
  foodBeverage('Food & Coffee', 'FOOD_BEVERAGE'),
  shopping('Shopping', 'SHOPPING'),
  entertainment('Entertainment', 'ENTERTAINMENT'),
  tourism('Tourism', 'TOURISM');

  final String label;
  final String code;
  const PlaceCategory(this.label, this.code);

  static PlaceCategory fromCode(String? raw) => switch (raw) {
        'FOOD_BEVERAGE' => PlaceCategory.foodBeverage,
        'SHOPPING' => PlaceCategory.shopping,
        'ENTERTAINMENT' => PlaceCategory.entertainment,
        'TOURISM' => PlaceCategory.tourism,
        _ => PlaceCategory.foodBeverage,
      };
}

/// Domain entity representing a discoverable place near a charging station.
class NearbyPlace extends Equatable {
  final String id;
  final String stationId;
  final String name;
  final PlaceCategory category;
  final String subCategory;
  final String address;
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final int walkingMinutes;
  final int avgVisitMinutes;
  final String openingHours;
  final bool isOpenNow;
  final double rating;
  final int reviewCount;
  final String priceLevel;
  final String phone;
  final String description;
  final List<String> tags;

  const NearbyPlace({
    required this.id,
    required this.stationId,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.avgVisitMinutes,
    required this.openingHours,
    required this.isOpenNow,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.phone,
    required this.description,
    required this.tags,
  });

  /// Total round-trip time: walk to place + activity duration + walk back to EV.
  int get totalRoundTripMinutes => (walkingMinutes * 2) + avgVisitMinutes;

  /// Whether the user can comfortably walk there, visit, and return before charging ends.
  bool fitsInTimeBudget(int availableChargingMinutes) =>
      totalRoundTripMinutes <= availableChargingMinutes + 5;

  /// Human-readable distance string (e.g., "120 m" or "0.7 km").
  String get formattedDistance => distanceMeters < 1000
      ? '$distanceMeters m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  @override
  List<Object?> get props => [
        id,
        stationId,
        name,
        category,
        distanceMeters,
        walkingMinutes,
        avgVisitMinutes,
        rating,
      ];
}
