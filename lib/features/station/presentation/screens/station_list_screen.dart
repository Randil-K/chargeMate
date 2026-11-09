import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/state_views.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_card.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_search_bar.dart';

class StationListScreen extends StatelessWidget {
  const StationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charging stations')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: StationSearchBar(),
          ),
          Expanded(
            child: BlocBuilder<StationsBloc, StationsState>(
              builder: (context, state) {
                switch (state.status) {
                  case StationsStatus.initial:
                  case StationsStatus.loading:
                    return const ShimmerList();
                  case StationsStatus.failure:
                    return MessageView.error(
                      state.error ?? 'Could not load stations',
                      onRetry: () => context
                          .read<StationsBloc>()
                          .add(const StationsRequested()),
                    );
                  case StationsStatus.ready:
                    if (state.visible.isEmpty) {
                      return const MessageView(
                        icon: Icons.search_off_rounded,
                        title: 'No stations match',
                        subtitle: 'Try a different search or clear filters.',
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async => context
                          .read<StationsBloc>()
                          .add(const StationsRequested()),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: state.visible.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimensions.spacing12),
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Text(
                              '${state.visible.length} stations found',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.textSecondary),
                            );
                          }
                          final s = state.visible[i - 1];
                          return StationCard(
                            station: s,
                            isFavourite: state.favourites.contains(s.id),
                            vehicleConnectors: state.vehicleConnectors,
                            onFavourite: () => context
                                .read<StationsBloc>()
                                .add(FavouriteToggled(s.id)),
                            onTap: () => context.push(AppRoutes.station(s.id)),
                          )
                              .animate()
                              .fadeIn(delay: (40 * i).clamp(0, 400).ms)
                              .slideY(begin: 0.06);
                        },
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
