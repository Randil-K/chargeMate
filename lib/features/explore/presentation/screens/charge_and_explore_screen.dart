import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';
import 'package:charge_mate/features/explore/domain/usecases/explore_usecases.dart';
import 'package:charge_mate/features/explore/presentation/bloc/explore_cubit.dart';
import 'package:charge_mate/features/explore/presentation/widgets/nearby_place_card.dart';
import 'package:charge_mate/features/session/presentation/bloc/charging_session_cubit.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/check_compatibility_usecase.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:charge_mate/injection.dart';

/// Module 4: Charge & Explore Screen.
///
/// Helps EV drivers discover nearby cafés, restaurants, shopping, and
/// attractions tailored to their available charging time window.
class ChargeAndExploreScreen extends StatefulWidget {
  final String stationId;
  const ChargeAndExploreScreen({super.key, required this.stationId});

  @override
  State<ChargeAndExploreScreen> createState() => _ChargeAndExploreScreenState();
}

class _ChargeAndExploreScreenState extends State<ChargeAndExploreScreen> {
  bool _showMap = false;

  int _initialMinutes(BuildContext context, ChargingStation? station) {
    final session = context.read<ChargingSessionCubit>().state;
    if (session.isActive && !session.isCompleted) {
      return session.remainingMinutes.clamp(10, 90);
    }
    final vehicle = context.read<VehicleBloc>().state.primary;
    if (vehicle == null || station == null) return 35;
    final compat = const CheckCompatibilityUseCase()(vehicle, station);
    return (compat.estimatedMinutes20to80 ?? 35).clamp(15, 90);
  }

  @override
  Widget build(BuildContext context) {
    final station = context.watch<StationsBloc>().state.byId(widget.stationId);
    if (station == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Charge & Explore')),
        body: const MessageView(
          icon: Icons.ev_station_outlined,
          title: 'Station not found',
        ),
      );
    }

    return BlocProvider(
      create: (ctx) => ExploreCubit(
        getPlaces: GetPlacesNearStationUseCase(sl()),
        initialChargingMinutes: _initialMinutes(ctx, station),
      )..loadPlaces(
          stationId: station.id,
          stationLat: station.latitude,
          stationLng: station.longitude,
        ),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Charge & Explore'),
              Text(
                station.name,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _showMap ? 'Show list' : 'Show walking map',
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(
                _showMap ? Icons.view_list_rounded : Icons.map_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        body: BlocBuilder<ExploreCubit, ExploreState>(
          builder: (context, state) {
            if (state.status == ExploreStatus.loading ||
                state.status == ExploreStatus.initial) {
              return const ShimmerList(count: 3, itemHeight: 160);
            }
            if (state.status == ExploreStatus.failure) {
              return MessageView.error(
                state.error ?? 'Failed to load nearby places',
              );
            }

            return Column(
              children: [
                _TimeBudgetHeader(state: state),
                _CategoryBar(selected: state.selectedCategory),
                Expanded(
                  child: _showMap
                      ? _WalkingRadiusMap(
                          station: station,
                          places: state.visiblePlaces,
                          chargingMinutes: state.chargingMinutes,
                        )
                      : state.visiblePlaces.isEmpty
                          ? const MessageView(
                              icon: Icons.explore_off_rounded,
                              title: 'No places match this filter',
                              subtitle:
                                  'Increase your charging time slider or select "All" categories.',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 32),
                              itemCount: state.visiblePlaces.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) => NearbyPlaceCard(
                                place: state.visiblePlaces[i],
                                chargingMinutes: state.chargingMinutes,
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TimeBudgetHeader extends StatelessWidget {
  final ExploreState state;
  const _TimeBudgetHeader({required this.state});

  static const _presets = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExploreCubit>();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.explore.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.explore, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available Charging Time: ${state.chargingMinutes} min',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusOperational.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '${state.fittingCount} fit window',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.statusOperational,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final mins in _presets)
                ChoiceChip(
                  label: Text('${mins}m'),
                  selected: state.chargingMinutes == mins,
                  selectedColor: AppColors.explore,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: state.chargingMinutes == mins
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => cubit.setChargingMinutes(mins),
                ),
            ],
          ),
          Slider(
            value: state.chargingMinutes.toDouble().clamp(10, 90),
            min: 10,
            max: 90,
            divisions: 16,
            activeColor: AppColors.explore,
            label: '${state.chargingMinutes} min',
            onChanged: (v) => cubit.setChargingMinutes(v.round()),
          ),
          Text(
            state.activityBanner,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.exploreLight,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                height: 24,
                child: Switch(
                  value: state.strictTimeFit,
                  activeThumbColor: AppColors.statusOperational,
                  onChanged: cubit.toggleStrictTimeFit,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Only show places that fit within my charging time',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final PlaceCategory selected;
  const _CategoryBar({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: PlaceCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = PlaceCategory.values[i];
          final isSelected = cat == selected;
          final color = placeCategoryColor(cat);
          return FilterChip(
            avatar: Icon(
              placeCategoryIcon(cat),
              size: 16,
              color: isSelected ? AppColors.textOnPrimary : color,
            ),
            label: Text(cat.label),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: color,
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) =>
                context.read<ExploreCubit>().selectCategory(cat),
          );
        },
      ),
    );
  }
}

class _WalkingRadiusMap extends StatelessWidget {
  final ChargingStation station;
  final List<NearbyPlace> places;
  final int chargingMinutes;

  const _WalkingRadiusMap({
    required this.station,
    required this.places,
    required this.chargingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(station.latitude, station.longitude);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.chargemate.charge_mate',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: 400,
              useRadiusInMeter: true,
              color: AppColors.explore.withValues(alpha: 0.08),
              borderColor: AppColors.explore.withValues(alpha: 0.45),
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Station marker at center
            Marker(
              point: center,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.ev_station_rounded,
                    color: AppColors.textOnPrimary, size: 22),
              ),
            ),
            for (final p in places)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 40,
                height: 40,
                child: Tooltip(
                  message: '${p.name} (${p.walkingMinutes}m walk)',
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.fitsInTimeBudget(chargingMinutes)
                            ? AppColors.statusOperational
                            : AppColors.explore,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      placeCategoryIcon(p.category),
                      color: placeCategoryColor(p.category),
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
