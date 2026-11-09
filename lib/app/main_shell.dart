import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

/// Hosts the four tabs with a floating frosted-glass bottom bar.
/// Also keeps [StationsBloc] aware of the primary vehicle's connectors.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.map_outlined, Icons.map_rounded, 'Map'),
    (Icons.electric_car_outlined, Icons.electric_car_rounded, 'Vehicles'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listenWhen: (a, b) => a.primary != b.primary,
      listener: (context, state) {
        final v = state.primary;
        context.read<StationsBloc>().add(
            VehicleConnectorsChanged(v?.connectorTypes ?? const {}, v?.displayName));
      },
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.bottomNavMargin, 0,
              AppDimensions.bottomNavMargin, AppDimensions.bottomNavMargin),
          child: SafeArea(
            child: Container(
              height: AppDimensions.bottomNavHeight - 8,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppDimensions.bottomNavRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: InkWell(
                            onTap: () => shell.goBranch(i,
                                initialLocation: i == shell.currentIndex),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: i == shell.currentIndex
                                        ? AppColors.primary
                                            .withValues(alpha: 0.18)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    i == shell.currentIndex
                                        ? _items[i].$2
                                        : _items[i].$1,
                                    color: i == shell.currentIndex
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _items[i].$3,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: i == shell.currentIndex
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
