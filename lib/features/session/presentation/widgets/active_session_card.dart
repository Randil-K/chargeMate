import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/features/session/presentation/bloc/charging_session_cubit.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/check_compatibility_usecase.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

/// Live telemetry banner displayed on the Home screen whenever a charging session is active.
class HomeActiveSessionBanner extends StatelessWidget {
  const HomeActiveSessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargingSessionCubit, ChargingSessionState>(
      builder: (context, session) {
        if (!session.isActive) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ActiveSessionTelemetryCard(session: session),
        );
      },
    );
  }
}

/// Interactive station charging session launcher / controller on StationDetailScreen.
class StationSessionControlCard extends StatelessWidget {
  final ChargingStation station;
  const StationSessionControlCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargingSessionCubit, ChargingSessionState>(
      builder: (context, session) {
        final isThisStationActive =
            session.isActive && session.stationId == station.id;
        if (isThisStationActive) {
          return _ActiveSessionTelemetryCard(session: session);
        }

        final vehicle = context.watch<VehicleBloc>().state.primary;
        final compat = vehicle != null
            ? const CheckCompatibilityUseCase()(vehicle, station)
            : null;
        final powerKw = (compat != null && compat.isCompatible)
            ? compat.effectiveKw
            : station.maxPowerKw;
        final bestPoint = (compat != null && compat.matchingPoints.isNotEmpty)
            ? compat.matchingPoints.first
            : (station.points.isNotEmpty ? station.points.first : null);
        final pricePerKwh = bestPoint?.pricePerKwh ?? station.minPrice ?? 85.0;
        final connector = bestPoint?.connectorType ?? 'CCS2';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulate Charging Session',
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      '${powerKw.toStringAsFixed(0)} kW ($connector) · Rs ${pricePerKwh.round()}/kWh',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textOnPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () {
                  context.read<ChargingSessionCubit>().startSession(
                        stationId: station.id,
                        stationName: station.name,
                        connectorType: connector,
                        vehicleName: vehicle?.displayName ?? 'BYD Atto 3',
                        powerKw: powerKw,
                        pricePerKwh: pricePerKwh,
                        batteryCapacityKwh: vehicle?.batteryKwh ?? 60.5,
                      );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveSessionTelemetryCard extends StatelessWidget {
  final ChargingSessionState session;
  const _ActiveSessionTelemetryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final socInt = session.currentSocPercent.round();
    final targetInt = session.targetSocPercent.round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      session.isCompleted
                          ? 'TARGET REACHED'
                          : 'CHARGING LIVE · ${session.powerKw.toStringAsFixed(0)} kW',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context
                    .read<ChargingSessionCubit>()
                    .fastForwardFiveMinutes(),
                icon: const Icon(Icons.fast_forward_rounded,
                    size: 16, color: AppColors.primary),
                label: Text(
                  '+5m Demo',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary),
                ),
              ),
              IconButton(
                tooltip: 'Stop charging session',
                onPressed: () =>
                    context.read<ChargingSessionCubit>().stopSession(),
                icon: const Icon(Icons.stop_circle_outlined,
                    color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            session.stationName ?? 'Charging Station',
            style: AppTextStyles.labelLarge,
          ),
          Text(
            '${session.vehicleName ?? 'EV'} · ${session.connectorType ?? 'CCS2'}',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricCol(
                label: 'Battery SoC',
                value: '$socInt% → $targetInt%',
                valueColor: AppColors.accent,
              ),
              _MetricCol(
                label: 'Energy Added',
                value: '${session.kwhDelivered.toStringAsFixed(1)} kWh',
              ),
              _MetricCol(
                label: 'Live Cost',
                value: 'Rs ${session.currentCostLkr.round()}',
              ),
              _MetricCol(
                label: 'Time Left',
                value: session.isCompleted
                    ? 'Done'
                    : '~${session.remainingMinutes} min',
                valueColor: AppColors.explore,
              ),
            ],
          ),
          if (session.stationId != null && !session.isCompleted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.explore,
                  side: BorderSide(
                    color: AppColors.explore.withValues(alpha: 0.6),
                  ),
                ),
                onPressed: () => context.push(
                  AppRoutes.stationExplore(session.stationId!),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(
                  'Explore Places for Your ${session.remainingMinutes} min Wait',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricCol({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
