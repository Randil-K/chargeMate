import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/utils/distance_utils.dart';
import 'package:charge_mate/core/utils/external_launcher.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/review/presentation/widgets/station_reviews_section.dart';
import 'package:charge_mate/features/session/presentation/widgets/active_session_card.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_badges.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/check_compatibility_usecase.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

class StationDetailScreen extends StatelessWidget {
  final String stationId;
  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsBloc, StationsState>(
      builder: (context, state) {
        final s = state.byId(stationId);
        if (s == null) {
          return Scaffold(
            appBar: AppBar(),
            body: state.status == StationsStatus.loading
                ? const LoadingIndicator()
                : const MessageView(
                    icon: Icons.ev_station_outlined,
                    title: 'Station not found',
                  ),
          );
        }
        final fav = state.favourites.contains(s.id);
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () =>
                    context.read<StationsBloc>().add(FavouriteToggled(s.id)),
                icon: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: fav ? AppColors.error : null,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              _Header(station: s),
              const SizedBox(height: AppDimensions.spacing20),
              _VehicleFit(station: s),
              const SizedBox(height: AppDimensions.spacing12),
              StationSessionControlCard(station: s),
              const SizedBox(height: AppDimensions.spacing12),
              _ExploreBanner(stationId: s.id),
              _section('Charging points'),
              for (final p in s.points)
                _PointTile(
                  point: p,
                  highlighted: state.vehicleConnectors.contains(p.connectorType),
                ),
              _section('Details'),
              _info(Icons.place_outlined, s.address),
              _info(Icons.schedule_rounded, s.openingHours),
              _info(Icons.business_rounded, s.operatorName),
              _info(Icons.phone_outlined, s.contactNumber),
              _info(
                Icons.verified_outlined,
                'Last verified ${DateFormat.yMMMd().format(s.lastVerified)}',
              ),
              if (s.status != StationStatus.operational)
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.spacing12),
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: stationStatusColor(s.status).withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Text(
                    'Status is community-reported and may not reflect '
                    'real-time availability.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              _section('Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in s.amenities) Chip(label: Text(a)),
                ],
              ),
              StationReviewsSection(station: s),
            ],
          ),
          bottomSheet: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Call',
                      icon: Icons.phone_rounded,
                      isOutlined: true,
                      onPressed: () async {
                        if (!await ExternalLauncher.call(s.contactNumber) &&
                            context.mounted) {
                          ExternalLauncher.showFailure(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Navigate',
                      icon: Icons.navigation_rounded,
                      onPressed: () async {
                        if (!await ExternalLauncher.navigateTo(
                                s.latitude, s.longitude) &&
                            context.mounted) {
                          ExternalLauncher.showFailure(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(title, style: AppTextStyles.headingSmall),
      );

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  final ChargingStation station;
  const _Header({required this.station});

  @override
  Widget build(BuildContext context) {
    final s = station;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(tag: 'power-${s.id}', child: PowerBadge(s.maxPowerKw, size: 68)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.name, style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text('${s.network} · ${s.city}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge.station(s.status),
                  const Icon(Icons.star_rounded,
                      size: 16, color: AppColors.warning),
                  Text('${s.rating} (${s.reviewCount})',
                      style: AppTextStyles.labelSmall),
                  if (s.distanceKm != null)
                    Text(DistanceUtils.format(s.distanceKm!),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows whether the user's primary vehicle can charge here, with ETA & cost.
class _VehicleFit extends StatelessWidget {
  final ChargingStation station;
  const _VehicleFit({required this.station});

  @override
  Widget build(BuildContext context) {
    final vehicle = context.watch<VehicleBloc>().state.primary;
    if (vehicle == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.electric_car_outlined,
                color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add your vehicle to see compatibility and charging time.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final r = const CheckCompatibilityUseCase()(vehicle, station);
    final color = r.isCompatible ? AppColors.accent : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.isCompatible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r.isCompatible
                      ? 'Compatible with your ${vehicle.displayName}'
                      : 'Not compatible with your ${vehicle.displayName}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
            ],
          ),
          if (r.isCompatible) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('Best rate', formatKw(r.effectiveKw)),
                if (r.estimatedMinutes20to80 != null)
                  _stat('20→80%', '~${r.estimatedMinutes20to80} min'),
                if (r.estimatedCostLkr != null)
                  _stat('Est. cost', 'Rs ${r.estimatedCostLkr!.round()}'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Estimates only — actual speed varies with battery & temperature.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Needs ${vehicle.connectorTypes.join(' / ')}; this station offers '
                '${station.connectorTypes.join(', ')}.',
                style: AppTextStyles.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.labelLarge),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _PointTile extends StatelessWidget {
  final ChargingPoint point;
  final bool highlighted;
  const _PointTile({required this.point, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
            color: highlighted
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.border),
      ),
      child: Row(
        children: [
          PowerBadge(point.powerKw, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${point.connectorType} · ${point.chargingType}',
                    style: AppTextStyles.labelLarge),
                if (point.pricePerKwh != null)
                  Text('Rs ${point.pricePerKwh!.round()} / kWh',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge.point(
            point.status,
            compact: true,
          ),
        ],
      ),
    );
  }
}

/// Prominent Charge & Explore entry card on the station detail screen.
class _ExploreBanner extends StatelessWidget {
  final String stationId;
  const _ExploreBanner({required this.stationId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: InkWell(
        onTap: () => context.push(AppRoutes.stationExplore(stationId)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.exploreGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.explore.withValues(alpha: 0.28),
                blurRadius: 16,
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
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Charge & Explore Nearby',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover cafés, dining, shopping & sights timed to your charge',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

