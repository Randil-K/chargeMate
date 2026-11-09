import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_badges.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:charge_mate/features/vehicle/presentation/screens/vehicle_list_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        final v = state.byId(vehicleId);
        if (v == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const MessageView(
                icon: Icons.electric_car_outlined, title: 'Vehicle not found'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(v.displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(AppRoutes.editVehicle(v.id)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              VehicleCard(vehicle: v, onTap: () {}),
              const SizedBox(height: 24),
              Text('Charging capability', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              for (final c in v.connectors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: PowerBadge(c.maxKw, size: 46),
                  title: Text(c.type, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    'Accepts up to ${formatKw(c.maxKw)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 16),
              if (!v.isVerifiedSpec)
                Text(
                  'Manually entered specs — compatibility depends on the '
                  'values you provided.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.warning),
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Find compatible stations',
                icon: Icons.ev_station_rounded,
                onPressed: () {
                  context.read<VehicleBloc>().add(PrimaryVehicleSet(v.id));
                  context
                      .read<StationsBloc>()
                      .add(const CompatibleOnlyToggled(true));
                  context.go(AppRoutes.map);
                },
              ),
              const SizedBox(height: 12),
              if (!v.isPrimary)
                CustomButton(
                  text: 'Set as primary',
                  isOutlined: true,
                  onPressed: () =>
                      context.read<VehicleBloc>().add(PrimaryVehicleSet(v.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}
