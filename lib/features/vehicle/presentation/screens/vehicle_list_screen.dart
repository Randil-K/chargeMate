import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_badges.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
                color: v.isPrimary
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.electric_car_rounded,
                        color: AppColors.textOnPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.displayName, style: AppTextStyles.labelLarge),
                        Text('${v.manufacturer} ${v.model} · ${v.year}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (v.isPrimary)
                    const StatusBadge(
                        label: 'Primary', color: AppColors.primary, compact: true),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat(Icons.battery_charging_full_rounded,
                      '${v.batteryKwh.toStringAsFixed(v.batteryKwh % 1 == 0 ? 0 : 1)} kWh'),
                  _stat(Icons.route_rounded, '${v.rangeKm} km'),
                  _stat(Icons.bolt_rounded, '${v.maxDcKw.round()} kW DC'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in v.connectors)
                    ConnectorChip(c.type, highlighted: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text) => Expanded(
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(child: Text(text, style: AppTextStyles.labelSmall)),
          ],
        ),
      );
}

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addVehicle),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
      ),
      body: BlocBuilder<VehicleBloc, VehicleState>(
        builder: (context, state) {
          if (state.status == VehicleStatus.loading ||
              state.status == VehicleStatus.initial) {
            return const ShimmerList(count: 3, itemHeight: 150);
          }
          if (state.status == VehicleStatus.failure) {
            return MessageView.error(state.error ?? 'Failed to load',
                onRetry: () =>
                    context.read<VehicleBloc>().add(const VehiclesRequested()));
          }
          if (state.vehicles.isEmpty) {
            return MessageView(
              icon: Icons.electric_car_outlined,
              title: 'No vehicles yet',
              subtitle:
                  'Add your EV to see which stations work with your connector.',
              actionLabel: 'Add vehicle',
              onAction: () => context.push(AppRoutes.addVehicle),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: state.vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = state.vehicles[i];
              return Dismissible(
                key: ValueKey(v.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.error),
                ),
                onDismissed: (_) {
                  final bloc = context.read<VehicleBloc>();
                  bloc.add(VehicleDeleted(v.id));
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text('${v.displayName} removed'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () => bloc.add(VehicleAdded(v)),
                      ),
                    ));
                },
                child: VehicleCard(
                  vehicle: v,
                  onTap: () => context.push(AppRoutes.vehicle(v.id)),
                ),
              ).animate().fadeIn(delay: (60 * i).ms).slideY(begin: 0.06);
            },
          );
        },
      ),
    );
  }
}
