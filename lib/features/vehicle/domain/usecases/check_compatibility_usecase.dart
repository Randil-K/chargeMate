import 'package:equatable/equatable.dart';

import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';

/// Result of matching a vehicle against a station.
class CompatibilityResult extends Equatable {
  final bool isCompatible;

  /// Points whose connector the vehicle accepts.
  final List<ChargingPoint> matchingPoints;

  /// Best real-world power: min(station point kW, vehicle max on that connector).
  final double effectiveKw;

  /// Estimated minutes for a typical 20% → 80% top-up.
  final int? estimatedMinutes20to80;

  /// Estimated cost in LKR for the same 20% → 80% session.
  final double? estimatedCostLkr;

  const CompatibilityResult({
    required this.isCompatible,
    required this.matchingPoints,
    required this.effectiveKw,
    this.estimatedMinutes20to80,
    this.estimatedCostLkr,
  });

  static const incompatible = CompatibilityResult(
    isCompatible: false,
    matchingPoints: [],
    effectiveKw: 0,
  );

  @override
  List<Object?> get props =>
      [isCompatible, matchingPoints, effectiveKw, estimatedMinutes20to80];
}

/// Pure domain service that decides whether a vehicle can charge at a
/// station, and estimates charging time and cost.
///
/// Compatibility is based on the vehicle's registered connector specs, not
/// assumptions from the model name. Time estimates are approximate: real
/// charging curves depend on temperature, battery state and charger load.
class CheckCompatibilityUseCase {
  const CheckCompatibilityUseCase();

  /// Average fraction of peak power delivered between 20–80% SoC.
  static const double _dcTaperFactor = 0.85;
  static const double _acEfficiency = 0.90;

  CompatibilityResult call(Vehicle vehicle, ChargingStation station) {
    final matching = station.points
        .where((p) => vehicle.connectorTypes.contains(p.connectorType))
        .toList();
    if (matching.isEmpty) return CompatibilityResult.incompatible;

    // Choose the point that gives the best effective power.
    ChargingPoint best = matching.first;
    double bestKw = 0;
    for (final p in matching) {
      final kw = _effectiveKw(vehicle, p);
      if (kw > bestKw) {
        bestKw = kw;
        best = p;
      }
    }

    final energyKwh = vehicle.batteryKwh * 0.6; // 20% → 80%
    final factor = best.isDc ? _dcTaperFactor : _acEfficiency;
    final minutes =
        bestKw > 0 ? (energyKwh / (bestKw * factor) * 60).round() : null;
    final cost =
        best.pricePerKwh != null ? energyKwh * best.pricePerKwh! : null;

    return CompatibilityResult(
      isCompatible: true,
      matchingPoints: matching,
      effectiveKw: bestKw,
      estimatedMinutes20to80: minutes,
      estimatedCostLkr: cost,
    );
  }

  double _effectiveKw(Vehicle v, ChargingPoint p) {
    // Per-connector limit first; fall back to the vehicle's AC/DC maximum.
    var limit = v.maxKwFor(p.connectorType);
    if (limit <= 0) limit = p.isDc ? v.maxDcKw : v.maxAcKw;
    // The car and the charger negotiate down to the lower of the two.
    return p.powerKw < limit ? p.powerKw : limit;
  }
}
