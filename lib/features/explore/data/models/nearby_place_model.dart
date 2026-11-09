import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';

/// DTO mapping JSON from Spring Boot `/api/places/nearby` or local mock asset.
class NearbyPlaceModel extends NearbyPlace {
  const NearbyPlaceModel({
    required super.id,
    required super.stationId,
    required super.name,
    required super.category,
    required super.subCategory,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.distanceMeters,
    required super.walkingMinutes,
    required super.avgVisitMinutes,
    required super.openingHours,
    required super.isOpenNow,
    required super.rating,
    required super.reviewCount,
    required super.priceLevel,
    required super.phone,
    required super.description,
    required super.tags,
  });

  factory NearbyPlaceModel.fromJson(Map<String, dynamic> json) =>
      NearbyPlaceModel(
        id: json['placeId'] as String,
        stationId: json['stationId'] as String,
        name: json['name'] as String,
        category: PlaceCategory.fromCode(json['category'] as String?),
        subCategory: json['subCategory'] as String? ?? 'Place',
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanceMeters: (json['distanceMeters'] as num).toInt(),
        walkingMinutes: (json['walkingMinutes'] as num).toInt(),
        avgVisitMinutes: (json['avgVisitMinutes'] as num).toInt(),
        openingHours: json['openingHours'] as String? ?? '08:00 – 22:00',
        isOpenNow: json['isOpenNow'] as bool? ?? true,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: (json['reviewCount'] as num).toInt(),
        priceLevel: json['priceLevel'] as String? ?? r'$$',
        phone: json['phone'] as String? ?? '+94 11 234 5678',
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      );
}
