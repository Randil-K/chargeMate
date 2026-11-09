import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:charge_mate/core/constants/api_endpoints.dart';
import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/features/explore/data/models/nearby_place_model.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';

abstract class ExploreRemoteDataSource {
  Future<List<NearbyPlaceModel>> fetchPlacesNearStation({
    required String stationId,
    required double stationLat,
    required double stationLng,
  });
}

/// Spring Boot implementation (`GET /api/places/nearby`).
class ApiExploreRemoteDataSource implements ExploreRemoteDataSource {
  final Dio _dio;
  const ApiExploreRemoteDataSource(this._dio);

  @override
  Future<List<NearbyPlaceModel>> fetchPlacesNearStation({
    required String stationId,
    required double stationLat,
    required double stationLng,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.nearbyPlaces,
        queryParameters: {
          'stationId': stationId,
          'lat': stationLat,
          'lng': stationLng,
        },
      );
      return (res.data as List)
          .map((e) => NearbyPlaceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException();
      }
      throw ServerException(statusCode: e.response?.statusCode);
    }
  }
}

/// Offline mock reading curated Sri Lankan places from `nearby_places.json`,
/// with fallback places synthesized around any station's coordinates so every
/// station in the app has a complete Charge & Explore experience.
class MockExploreRemoteDataSource implements ExploreRemoteDataSource {
  static const _asset = 'assets/mock_data/nearby_places.json';
  List<NearbyPlaceModel>? _cache;

  @override
  Future<List<NearbyPlaceModel>> fetchPlacesNearStation({
    required String stationId,
    required double stationLat,
    required double stationLng,
  }) async {
    try {
      _cache ??= (jsonDecode(await rootBundle.loadString(_asset)) as List)
          .map((e) => NearbyPlaceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final matches =
          _cache!.where((p) => p.stationId == stationId).toList();
      if (matches.isNotEmpty) return matches;

      // Fallback places for stations without bespoke entries so live demos
      // work seamlessly on every station marker.
      return _fallbackPlaces(stationId, stationLat, stationLng);
    } catch (e) {
      throw ServerException(message: 'Failed to load nearby places: $e');
    }
  }

  List<NearbyPlaceModel> _fallbackPlaces(
      String stationId, double lat, double lng) {
    return [
      NearbyPlaceModel(
        id: '$stationId-pl-1',
        stationId: stationId,
        name: 'Barista Express & Bakery',
        category: PlaceCategory.foodBeverage,
        subCategory: 'Coffee & Bakery',
        address: '120 m from charging bay',
        latitude: lat + 0.0009,
        longitude: lng + 0.0007,
        distanceMeters: 120,
        walkingMinutes: 2,
        avgVisitMinutes: 15,
        openingHours: '07:00 – 22:00',
        isOpenNow: true,
        rating: 4.5,
        reviewCount: 142,
        priceLevel: r'$$',
        phone: '+94 11 234 5500',
        description:
            'Air-conditioned espresso bar with Ceylon tea, pastries, and free Wi-Fi.',
        tags: const ['Coffee', 'Wi-Fi', 'Quick Bite'],
      ),
      NearbyPlaceModel(
        id: '$stationId-pl-2',
        stationId: stationId,
        name: 'Keells Super Market & Pharmacy',
        category: PlaceCategory.shopping,
        subCategory: 'Supermarket',
        address: '190 m from charging bay',
        latitude: lat - 0.0011,
        longitude: lng + 0.0009,
        distanceMeters: 190,
        walkingMinutes: 3,
        avgVisitMinutes: 20,
        openingHours: '07:30 – 22:30',
        isOpenNow: true,
        rating: 4.4,
        reviewCount: 218,
        priceLevel: r'$$',
        phone: '+94 11 230 3500',
        description:
            'Full supermarket with fresh juice counter, bakery, ATM, and clean restrooms.',
        tags: const ['Supermarket', 'Juice Bar', 'ATM', 'Restrooms'],
      ),
      NearbyPlaceModel(
        id: '$stationId-pl-3',
        stationId: stationId,
        name: 'Spice Garden Family Restaurant',
        category: PlaceCategory.foodBeverage,
        subCategory: 'Sri Lankan & Chinese',
        address: '320 m from charging bay',
        latitude: lat + 0.0018,
        longitude: lng - 0.0014,
        distanceMeters: 320,
        walkingMinutes: 4,
        avgVisitMinutes: 35,
        openingHours: '10:30 – 22:30',
        isOpenNow: true,
        rating: 4.6,
        reviewCount: 189,
        priceLevel: r'$$',
        phone: '+94 11 277 8899',
        description:
            'Authentic rice & curry, kottu, and fresh tropical fruit juices in a shaded courtyard.',
        tags: const ['Lunch & Dinner', 'Air Conditioned', 'Family'],
      ),
      NearbyPlaceModel(
        id: '$stationId-pl-4',
        stationId: stationId,
        name: 'Heritage Cultural Walk & Viewpoint',
        category: PlaceCategory.tourism,
        subCategory: 'Scenic Attraction',
        address: '480 m from charging bay',
        latitude: lat - 0.0025,
        longitude: lng - 0.0020,
        distanceMeters: 480,
        walkingMinutes: 6,
        avgVisitMinutes: 35,
        openingHours: '06:00 – 19:30',
        isOpenNow: true,
        rating: 4.7,
        reviewCount: 310,
        priceLevel: 'Free',
        phone: '+94 11 243 7059',
        description:
            'Shaded walking path and local heritage viewpoint—perfect for a 45-minute charging break.',
        tags: const ['Scenic', 'Walking Path', 'Photography'],
      ),
    ];
  }
}
