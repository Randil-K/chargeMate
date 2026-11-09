import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_card.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_search_bar.dart';

/// Full-screen map interface utilizing dark cartography with high-visibility EV pins.
class StationMapScreen extends StatefulWidget {
  const StationMapScreen({super.key});

  @override
  State<StationMapScreen> createState() => _StationMapScreenState();
}

class _StationMapScreenState extends State<StationMapScreen> {
  final _controller = MapController();
  String? _selectedId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(ChargingStation s) {
    setState(() => _selectedId = s.id);
    _controller.move(LatLng(s.latitude, s.longitude), 13.5);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsBloc, StationsState>(
      builder: (context, state) {
        ChargingStation? selected;
        for (final s in state.visible) {
          if (s.id == _selectedId) selected = s;
        }
        final origin = LatLng(state.origin.latitude, state.origin.longitude);

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: origin,
                  initialZoom: AppConstants.defaultZoom - 1,
                  onTap: (_, _) => setState(() => _selectedId = null),
                ),
                children: [
                  TileLayer(
                    // CARTO dark basemap (OpenStreetMap) — High-contrast night cartography
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.chargemate.charge_mate',
                  ),
                  MarkerLayer(
                    markers: [
                      // User's current location beacon
                      Marker(
                        point: origin,
                        width: 26,
                        height: 26,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Station pins with glanceable speed & status iconography
                      for (final s in state.visible)
                        Marker(
                          point: LatLng(s.latitude, s.longitude),
                          width: s.id == _selectedId ? 52 : 42,
                          height: s.id == _selectedId ? 52 : 42,
                          child: GestureDetector(
                            onTap: () => _select(s),
                            child: _StationMarker(
                              station: s,
                              selected: s.id == _selectedId,
                              compatible: state.isCompatible(s),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                      TextSourceAttribution('© CARTO'),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StationSearchBar(),
                      if (state.locationNotice != null) ...[
                        const SizedBox(height: AppDimensions.spacing8),
                        Chip(
                          avatar: const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.explore,
                          ),
                          label: Text(state.locationNotice!),
                          backgroundColor: AppColors.surfaceElevated,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.status == StationsStatus.loading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              Positioned(
                right: 16,
                bottom: selected != null ? 230 : 110,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onPressed: () => _controller.move(origin, 13),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              if (selected != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: StationCard(
                    station: selected,
                    isFavourite: state.favourites.contains(selected.id),
                    vehicleConnectors: state.vehicleConnectors,
                    onFavourite: () => context
                        .read<StationsBloc>()
                        .add(FavouriteToggled(selected!.id)),
                    onTap: () =>
                        context.push(AppRoutes.station(selected!.id)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StationMarker extends StatelessWidget {
  final ChargingStation station;
  final bool selected;
  final bool compatible;

  const _StationMarker({
    required this.station,
    required this.selected,
    required this.compatible,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = station.status == StationStatus.offline;
    final isIssues = station.status == StationStatus.issuesReported;
    final color = isOffline
        ? AppColors.statusOffline
        : isIssues
            ? AppColors.statusIssues
            : AppColors.chargingSpeedColor(station.maxPowerKw);

    final icon = isOffline
        ? Icons.cancel_rounded
        : isIssues
            ? Icons.warning_amber_rounded
            : station.maxPowerKw >= 100
                ? Icons.electric_bolt_rounded
                : Icons.bolt_rounded;

    final size = selected ? 48.0 : 36.0;

    return Opacity(
      opacity: compatible ? 1 : 0.35,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: selected ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.6 : 0.25),
              blurRadius: selected ? 16 : 8,
              spreadRadius: selected ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.58,
        ),
      ),
    );
  }
}
