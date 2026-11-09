import 'package:flutter_test/flutter_test.dart';

import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';
import 'package:charge_mate/features/explore/domain/usecases/explore_usecases.dart';
import 'package:charge_mate/features/session/presentation/bloc/charging_session_cubit.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/domain/entities/station_filter.dart';
import 'package:charge_mate/features/station/domain/usecases/station_usecases.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/check_compatibility_usecase.dart';

void main() {
  final sampleStation = ChargingStation(
    id: 'st-001',
    name: 'chargeNET Colombo City Centre',
    address: '137 Sir James Peiris Mawatha',
    city: 'Colombo',
    latitude: 6.9186,
    longitude: 79.8553,
    operatorName: 'chargeNET',
    network: 'chargeNET',
    openingHours: '24 Hours',
    contactNumber: '+94 11 234 5678',
    status: StationStatus.operational,
    lastVerified: DateTime(2026, 3, 1),
    rating: 4.7,
    reviewCount: 42,
    amenities: const ['Restrooms', 'Mall'],
    points: const [
      ChargingPoint(
        id: 'pt-1',
        connectorType: 'CCS2',
        chargingType: 'DC',
        powerKw: 120,
        status: PointStatus.available,
        pricePerKwh: 95,
      ),
      ChargingPoint(
        id: 'pt-2',
        connectorType: 'Type 2',
        chargingType: 'AC',
        powerKw: 22,
        status: PointStatus.available,
        pricePerKwh: 70,
      ),
    ],
  );

  group('CheckCompatibilityUseCase', () {
    const useCase = CheckCompatibilityUseCase();

    test('caps effective kW at vehicle maxDcKw and computes 20->80% time & cost', () {
      const atto3 = Vehicle(
        id: 'v-1',
        manufacturer: 'BYD',
        model: 'Atto 3',
        year: 2024,
        batteryKwh: 60.5,
        rangeKm: 420,
        connectors: [
          VehicleConnector(type: 'CCS2', maxKw: 88),
          VehicleConnector(type: 'Type 2', maxKw: 7),
        ],
        maxAcKw: 7,
        maxDcKw: 88,
      );

      final result = useCase(atto3, sampleStation);

      expect(result.isCompatible, isTrue);
      expect(result.effectiveKw, equals(88));
      expect(result.estimatedMinutes20to80, isNotNull);
      expect(result.estimatedMinutes20to80, greaterThan(20));
      expect(result.estimatedCostLkr, closeTo(60.5 * 0.6 * 95, 0.1));
    });

    test('returns incompatible when vehicle only supports CHAdeMO and Type 1', () {
      const oldLeaf = Vehicle(
        id: 'v-2',
        manufacturer: 'Nissan',
        model: 'Leaf AZEO',
        year: 2016,
        batteryKwh: 30,
        rangeKm: 170,
        connectors: [
          VehicleConnector(type: 'CHAdeMO', maxKw: 50),
          VehicleConnector(type: 'Type 1', maxKw: 6.6),
        ],
        maxAcKw: 6.6,
        maxDcKw: 50,
      );

      final result = useCase(oldLeaf, sampleStation);
      expect(result.isCompatible, isFalse);
      expect(result.effectiveKw, equals(0));
    });
  });

  group('RecommendPlacesByTimeUseCase', () {
    const useCase = RecommendPlacesByTimeUseCase();

    const places = [
      NearbyPlace(
        id: 'p-1',
        stationId: 'st-001',
        name: 'Barista Express',
        category: PlaceCategory.foodBeverage,
        subCategory: 'Coffee Shop',
        address: 'Colombo 02',
        latitude: 6.9188,
        longitude: 79.8555,
        distanceMeters: 160,
        walkingMinutes: 2,
        avgVisitMinutes: 15,
        openingHours: '07:00 - 22:00',
        isOpenNow: true,
        rating: 4.6,
        reviewCount: 80,
        priceLevel: 'Rs 900',
        phone: '+94 11 200 1000',
        description: 'Quick espresso bar',
        tags: ['Coffee', 'Wi-Fi'],
      ),
      NearbyPlace(
        id: 'p-2',
        stationId: 'st-001',
        name: 'Gangaramaya Temple & Museum',
        category: PlaceCategory.tourism,
        subCategory: 'Cultural Landmark',
        address: 'Colombo 02',
        latitude: 6.9200,
        longitude: 79.8570,
        distanceMeters: 450,
        walkingMinutes: 6,
        avgVisitMinutes: 45,
        openingHours: '06:00 - 22:00',
        isOpenNow: true,
        rating: 4.8,
        reviewCount: 120,
        priceLevel: 'Rs 500',
        phone: '+94 11 232 7084',
        description: 'Historic Buddhist temple complex',
        tags: ['Culture', 'Sightseeing'],
      ),
    ];

    test('strictTimeFit filters out places exceeding round-trip + activity budget', () {
      final result30Min = useCase(
        places,
        chargingMinutes: 30,
        strictTimeFit: true,
      );

      expect(result30Min.length, equals(1));
      expect(result30Min.first.id, equals('p-1'));
      expect(result30Min.first.totalRoundTripMinutes, equals(19));
    });

    test('filters by PlaceCategory when specified', () {
      final tourismPlaces = useCase(
        places,
        category: PlaceCategory.tourism,
        chargingMinutes: 60,
        strictTimeFit: true,
      );

      expect(tourismPlaces.length, equals(1));
      expect(tourismPlaces.first.id, equals('p-2'));
    });
  });

  group('FilterStationsUseCase', () {
    const useCase = FilterStationsUseCase();

    test('filters by query and minimum power kW', () {
      final filtered = useCase(
        [sampleStation],
        query: 'Colombo',
        filter: const StationFilter(minPowerKw: 100),
      );
      expect(filtered.length, equals(1));

      final tooHighKw = useCase(
        [sampleStation],
        filter: const StationFilter(minPowerKw: 150),
      );
      expect(tooHighKw, isEmpty);
    });
  });

  group('ChargingSessionCubit', () {
    test('starts session, fast-forwards 5 minutes, and updates SoC, kWh & cost', () async {
      final cubit = ChargingSessionCubit();
      cubit.startSession(
        stationId: 'st-001',
        stationName: 'chargeNET Colombo City Centre',
        connectorType: 'CCS2',
        vehicleName: 'BYD Atto 3',
        powerKw: 88,
        pricePerKwh: 95,
        batteryCapacityKwh: 60.5,
      );

      expect(cubit.state.isActive, isTrue);
      expect(cubit.state.currentSocPercent, equals(20.0));

      cubit.fastForwardFiveMinutes();
      expect(cubit.state.currentSocPercent, greaterThan(25.0));
      expect(cubit.state.kwhDelivered, greaterThan(3.0));
      expect(cubit.state.currentCostLkr, greaterThan(280.0));

      cubit.stopSession();
      expect(cubit.state.isActive, isFalse);
      await cubit.close();
    });
  });
}
