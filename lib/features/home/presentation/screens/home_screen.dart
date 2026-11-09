import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/session/presentation/widgets/active_session_card.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_card.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              context.read<StationsBloc>().add(const StationsRequested()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        Text(user?.firstName ?? 'Driver',
                            style: AppTextStyles.displaySmall),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.secondary,
                      child: Text(user?.initials ?? '?',
                          style: AppTextStyles.labelLarge),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.go(AppRoutes.map),
                child: Container(
                  height: AppDimensions.searchBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text('Find a charging station',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _action(context, Icons.map_rounded, 'Map', AppColors.primary,
                      () => context.go(AppRoutes.map)),
                  _action(context, Icons.list_rounded, 'All stations',
                      AppColors.secondary, () => context.push(AppRoutes.stations)),
                  _action(context, Icons.electric_car_rounded, 'Vehicles',
                      AppColors.accent, () => context.go(AppRoutes.vehicles)),
                  _action(context, Icons.favorite_rounded, 'Favourites',
                      AppColors.error, () => context.push(AppRoutes.favourites)),
                ],
              ),
              const SizedBox(height: 24),
              const HomeActiveSessionBanner(),
              const _VehicleBanner(),
              const SizedBox(height: 14),
              const _HomeExploreCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Nearby stations', style: AppTextStyles.headingSmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.stations),
                    child: const Text('See all'),
                  ),
                ],
              ),
              BlocBuilder<StationsBloc, StationsState>(
                builder: (context, state) {
                  if (state.status == StationsStatus.loading && state.all.isEmpty) {
                    return const SizedBox(
                        height: 300, child: ShimmerList(count: 2, itemHeight: 130));
                  }
                  if (state.status == StationsStatus.failure && state.all.isEmpty) {
                    return MessageView.error(state.error ?? 'Failed',
                        onRetry: () => context
                            .read<StationsBloc>()
                            .add(const StationsRequested()));
                  }
                  final nearby = state.all.take(4).toList();
                  return Column(
                    children: [
                      for (var i = 0; i < nearby.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: StationCard(
                            station: nearby[i],
                            compact: true,
                            isFavourite: state.favourites.contains(nearby[i].id),
                            vehicleConnectors: state.vehicleConnectors,
                            onFavourite: () => context
                                .read<StationsBloc>()
                                .add(FavouriteToggled(nearby[i].id)),
                            onTap: () =>
                                context.push(AppRoutes.station(nearby[i].id)),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VehicleBanner extends StatelessWidget {
  const _VehicleBanner();

  @override
  Widget build(BuildContext context) {
    final v = context.watch<VehicleBloc>().state.primary;
    return GestureDetector(
      onTap: () => context.go(AppRoutes.vehicles),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.electric_car_rounded,
                size: 36, color: AppColors.textOnPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v == null ? 'Add your EV' : v.displayName,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textOnPrimary),
                  ),
                  Text(
                    v == null
                        ? 'Get compatible-station recommendations'
                        : '${v.connectorTypes.join(' · ')} · ${v.rangeKm} km range',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textOnPrimary),
          ],
        ),
      ),
    );
  }
}

class _HomeExploreCard extends StatelessWidget {
  const _HomeExploreCard();

  @override
  Widget build(BuildContext context) {
    final nearestId =
        context.watch<StationsBloc>().state.all.firstOrNull?.id ?? 'st-001';
    return GestureDetector(
      onTap: () => context.push(AppRoutes.stationExplore(nearestId)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.exploreGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.explore.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Charge & Explore',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Find cafés, dining & sights matched to your charging time',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
