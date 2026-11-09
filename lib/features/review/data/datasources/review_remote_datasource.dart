import 'package:charge_mate/core/constants/api_endpoints.dart';
import 'package:charge_mate/core/network/dio_client.dart';
import 'package:charge_mate/features/review/domain/entities/station_review.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

abstract class ReviewRemoteDataSource {
  Future<List<StationReview>> getReviewsForStation(String stationId);
  Future<StationReview> submitReview(StationReview review);
}

/// Offline-first mock data source with realistic Sri Lankan EV community reviews.
class MockReviewRemoteDataSource implements ReviewRemoteDataSource {
  final Map<String, List<StationReview>> _store = {};

  List<StationReview> _seedForStation(String stationId) {
    final now = DateTime.now();
    return [
      StationReview(
        id: 'rev-$stationId-1',
        stationId: stationId,
        userName: 'Nimal Jayasuriya',
        userInitials: 'NJ',
        vehicleName: 'BYD Atto 3',
        rating: 5,
        comment:
            'Fast CCS2 handshake, got 52 kW steady from 22% to 80% in about 35 minutes. Clean parking bay and security on site.',
        reportedStatus: StationStatus.operational,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      StationReview(
        id: 'rev-$stationId-2',
        stationId: stationId,
        userName: 'Dilani Rodrigo',
        userInitials: 'DR',
        vehicleName: 'Nissan Leaf e+',
        rating: 4,
        comment:
            'CHAdeMO cable works reliably. Great spot to use Charge & Explore for a quick coffee while topping up.',
        reportedStatus: StationStatus.operational,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      StationReview(
        id: 'rev-$stationId-3',
        stationId: stationId,
        userName: 'Tharindu Fernando',
        userInitials: 'TF',
        vehicleName: 'MG ZS EV',
        rating: 5,
        comment:
            'One of the most dependable chargers in the area. Easy access even during evening traffic.',
        reportedStatus: StationStatus.operational,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
    ];
  }

  @override
  Future<List<StationReview>> getReviewsForStation(String stationId) async {
    return List.unmodifiable(
      _store.putIfAbsent(stationId, () => _seedForStation(stationId)),
    );
  }

  @override
  Future<StationReview> submitReview(StationReview review) async {
    final list = _store.putIfAbsent(
      review.stationId,
      () => _seedForStation(review.stationId),
    );
    list.insert(0, review);
    return review;
  }
}

/// Spring Boot REST API implementation for production backend parity.
class ApiReviewRemoteDataSource implements ReviewRemoteDataSource {
  final DioClient _client;
  const ApiReviewRemoteDataSource(this._client);

  @override
  Future<List<StationReview>> getReviewsForStation(String stationId) async {
    final res = await _client.get(ApiEndpoints.stationReviews(stationId));
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((raw) {
      final map = raw as Map<String, dynamic>;
      return StationReview(
        id: map['id']?.toString() ?? '',
        stationId: stationId,
        userName: map['userName']?.toString() ?? 'EV Driver',
        userInitials: map['userInitials']?.toString() ?? 'EV',
        vehicleName: map['vehicleName']?.toString(),
        rating: (map['rating'] as num?)?.toInt() ?? 5,
        comment: map['comment']?.toString() ?? '',
        reportedStatus: StationStatus.operational,
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<StationReview> submitReview(StationReview review) async {
    await _client.post(
      ApiEndpoints.stationReviews(review.stationId),
      data: {
        'rating': review.rating,
        'comment': review.comment,
        'vehicleName': review.vehicleName,
        'reportedStatus': review.reportedStatus?.name,
      },
    );
    return review;
  }
}
