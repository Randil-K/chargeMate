import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChargingSessionState extends Equatable {
  final bool isActive;
  final String? stationId;
  final String? stationName;
  final String? connectorType;
  final String? vehicleName;
  final double powerKw;
  final double pricePerKwh;
  final double batteryCapacityKwh;
  final double startSocPercent;
  final double currentSocPercent;
  final double targetSocPercent;
  final int elapsedSeconds;

  const ChargingSessionState({
    this.isActive = false,
    this.stationId,
    this.stationName,
    this.connectorType,
    this.vehicleName,
    this.powerKw = 50.0,
    this.pricePerKwh = 85.0,
    this.batteryCapacityKwh = 60.0,
    this.startSocPercent = 20.0,
    this.currentSocPercent = 20.0,
    this.targetSocPercent = 80.0,
    this.elapsedSeconds = 0,
  });

  static const idle = ChargingSessionState();

  /// Total kWh delivered since session started.
  double get kwhDelivered =>
      ((currentSocPercent - startSocPercent).clamp(0.0, 100.0) / 100.0) *
      batteryCapacityKwh;

  /// Accumulated cost in Sri Lankan Rupees (LKR).
  double get currentCostLkr => kwhDelivered * pricePerKwh;

  /// Remaining kWh needed to reach target SoC.
  double get remainingKwh =>
      ((targetSocPercent - currentSocPercent).clamp(0.0, 100.0) / 100.0) *
      batteryCapacityKwh;

  /// Estimated minutes remaining at effective power (accounting for 0.85 taper).
  int get remainingMinutes {
    if (!isActive || powerKw <= 0 || isCompleted) return 0;
    final mins = (remainingKwh / (powerKw * 0.85)) * 60.0;
    return mins.ceil().clamp(1, 240);
  }

  /// Session completion ratio (0.0 -> 1.0).
  double get progress {
    final span = targetSocPercent - startSocPercent;
    if (span <= 0) return 1.0;
    return ((currentSocPercent - startSocPercent) / span).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentSocPercent >= targetSocPercent;

  String get formattedElapsed {
    final m = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  ChargingSessionState copyWith({
    bool? isActive,
    String? stationId,
    String? stationName,
    String? connectorType,
    String? vehicleName,
    double? powerKw,
    double? pricePerKwh,
    double? batteryCapacityKwh,
    double? startSocPercent,
    double? currentSocPercent,
    double? targetSocPercent,
    int? elapsedSeconds,
  }) =>
      ChargingSessionState(
        isActive: isActive ?? this.isActive,
        stationId: stationId ?? this.stationId,
        stationName: stationName ?? this.stationName,
        connectorType: connectorType ?? this.connectorType,
        vehicleName: vehicleName ?? this.vehicleName,
        powerKw: powerKw ?? this.powerKw,
        pricePerKwh: pricePerKwh ?? this.pricePerKwh,
        batteryCapacityKwh: batteryCapacityKwh ?? this.batteryCapacityKwh,
        startSocPercent: startSocPercent ?? this.startSocPercent,
        currentSocPercent: currentSocPercent ?? this.currentSocPercent,
        targetSocPercent: targetSocPercent ?? this.targetSocPercent,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      );

  @override
  List<Object?> get props => [
        isActive,
        stationId,
        stationName,
        connectorType,
        vehicleName,
        powerKw,
        pricePerKwh,
        batteryCapacityKwh,
        startSocPercent,
        currentSocPercent,
        targetSocPercent,
        elapsedSeconds,
      ];
}

/// Manages a simulated live EV charging session with real-time telemetry updates.
class ChargingSessionCubit extends Cubit<ChargingSessionState> {
  Timer? _timer;

  ChargingSessionCubit() : super(ChargingSessionState.idle);

  void startSession({
    required String stationId,
    required String stationName,
    required String connectorType,
    required String vehicleName,
    required double powerKw,
    required double pricePerKwh,
    required double batteryCapacityKwh,
    double startSoc = 20.0,
    double targetSoc = 80.0,
  }) {
    _timer?.cancel();
    emit(ChargingSessionState(
      isActive: true,
      stationId: stationId,
      stationName: stationName,
      connectorType: connectorType,
      vehicleName: vehicleName,
      powerKw: powerKw > 0 ? powerKw : 50.0,
      pricePerKwh: pricePerKwh > 0 ? pricePerKwh : 85.0,
      batteryCapacityKwh: batteryCapacityKwh > 0 ? batteryCapacityKwh : 60.0,
      startSocPercent: startSoc,
      currentSocPercent: startSoc,
      targetSocPercent: targetSoc,
      elapsedSeconds: 0,
    ));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick(1));
  }

  /// Advances the simulated charging session by [seconds].
  /// Accelerated slightly so live movement is visible every second during demos.
  void _onTick(int seconds) {
    if (!state.isActive || state.isCompleted) return;
    // Real energy added in `seconds` at effective power * 0.85 taper
    // For demo visibility, 1 real second = 5 simulated charging seconds
    final simHours = (seconds * 5.0) / 3600.0;
    final addedKwh = state.powerKw * 0.85 * simHours;
    final addedSoc = (addedKwh / state.batteryCapacityKwh) * 100.0;
    final nextSoc =
        (state.currentSocPercent + addedSoc).clamp(0.0, state.targetSocPercent);

    emit(state.copyWith(
      currentSocPercent: nextSoc,
      elapsedSeconds: state.elapsedSeconds + seconds,
    ));
  }

  /// Demo helper: fast-forwards the charging session by 5 simulated minutes.
  void fastForwardFiveMinutes() {
    if (!state.isActive || state.isCompleted) return;
    const simMinutes = 5;
    final addedKwh = state.powerKw * 0.85 * (simMinutes / 60.0);
    final addedSoc = (addedKwh / state.batteryCapacityKwh) * 100.0;
    final nextSoc =
        (state.currentSocPercent + addedSoc).clamp(0.0, state.targetSocPercent);

    emit(state.copyWith(
      currentSocPercent: nextSoc,
      elapsedSeconds: state.elapsedSeconds + (simMinutes * 60),
    ));
  }

  void stopSession() {
    _timer?.cancel();
    _timer = null;
    emit(ChargingSessionState.idle);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
