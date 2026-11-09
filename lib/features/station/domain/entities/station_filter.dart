import 'package:equatable/equatable.dart';

import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

enum StationSort { distance, power, rating }

/// Immutable set of filter criteria applied to the station list.
class StationFilter extends Equatable {
  final Set<String> connectorTypes;
  final double minPowerKw;
  final bool onlyOperational;
  final bool onlyAvailableNow;
  final bool only24Hours;
  final Set<String> networks;
  final StationSort sort;

  const StationFilter({
    this.connectorTypes = const {},
    this.minPowerKw = 0,
    this.onlyOperational = false,
    this.onlyAvailableNow = false,
    this.only24Hours = false,
    this.networks = const {},
    this.sort = StationSort.distance,
  });

  static const none = StationFilter();

  /// Number of active criteria — shown as a badge on the filter button.
  int get activeCount =>
      (connectorTypes.isNotEmpty ? 1 : 0) +
      (minPowerKw > 0 ? 1 : 0) +
      (onlyOperational ? 1 : 0) +
      (onlyAvailableNow ? 1 : 0) +
      (only24Hours ? 1 : 0) +
      (networks.isNotEmpty ? 1 : 0);

  bool matches(ChargingStation s) {
    if (connectorTypes.isNotEmpty && !s.supportsAny(connectorTypes)) {
      return false;
    }
    if (minPowerKw > 0 && s.maxPowerKw < minPowerKw) return false;
    if (onlyOperational && s.status != StationStatus.operational) return false;
    if (onlyAvailableNow && s.availableCount == 0) return false;
    if (only24Hours && !s.is24Hours) return false;
    if (networks.isNotEmpty && !networks.contains(s.network)) return false;
    return true;
  }

  StationFilter copyWith({
    Set<String>? connectorTypes,
    double? minPowerKw,
    bool? onlyOperational,
    bool? onlyAvailableNow,
    bool? only24Hours,
    Set<String>? networks,
    StationSort? sort,
  }) =>
      StationFilter(
        connectorTypes: connectorTypes ?? this.connectorTypes,
        minPowerKw: minPowerKw ?? this.minPowerKw,
        onlyOperational: onlyOperational ?? this.onlyOperational,
        onlyAvailableNow: onlyAvailableNow ?? this.onlyAvailableNow,
        only24Hours: only24Hours ?? this.only24Hours,
        networks: networks ?? this.networks,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [
        connectorTypes,
        minPowerKw,
        onlyOperational,
        onlyAvailableNow,
        only24Hours,
        networks,
        sort,
      ];
}
