import 'package:equatable/equatable.dart';

import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

/// A driver review and optional community status report for a charging station.
class StationReview extends Equatable {
  final String id;
  final String stationId;
  final String userName;
  final String userInitials;
  final String? vehicleName;
  final int rating; // 1..5
  final String comment;
  final StationStatus? reportedStatus;
  final DateTime createdAt;

  const StationReview({
    required this.id,
    required this.stationId,
    required this.userName,
    required this.userInitials,
    this.vehicleName,
    required this.rating,
    required this.comment,
    this.reportedStatus,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        stationId,
        userName,
        userInitials,
        vehicleName,
        rating,
        comment,
        reportedStatus,
        createdAt,
      ];
}
