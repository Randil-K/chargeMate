import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/station/presentation/widgets/filter_bottom_sheet.dart';

/// Search field + filter button + "fits my car" toggle, shared by map & list.
class StationSearchBar extends StatefulWidget {
  final bool showCompatibleToggle;
  const StationSearchBar({super.key, this.showCompatibleToggle = true});

  @override
  State<StationSearchBar> createState() => _StationSearchBarState();
}

class _StationSearchBarState extends State<StationSearchBar> {
  late final TextEditingController _ctrl = TextEditingController(
      text: context.read<StationsBloc>().state.query);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openFilters(StationsState state) async {
    final networks = state.all.map((s) => s.network).toSet().toList()..sort();
    final result = await FilterBottomSheet.show(context,
        initial: state.filter, networks: networks);
    if (result != null && mounted) {
      context.read<StationsBloc>().add(StationFilterChanged(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationsBloc, StationsState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: AppDimensions.searchBarHeight,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 12),
                    ],
                  ),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (q) =>
                        context.read<StationsBloc>().add(StationSearchChanged(q)),
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search city, station or network',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary),
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _ctrl.clear();
                                context
                                    .read<StationsBloc>()
                                    .add(const StationSearchChanged(''));
                              },
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Badge(
                isLabelVisible: state.filter.activeCount > 0,
                label: Text('${state.filter.activeCount}'),
                backgroundColor: AppColors.primary,
                textColor: AppColors.textOnPrimary,
                child: Material(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  shape: const CircleBorder(
                      side: BorderSide(color: AppColors.border)),
                  child: IconButton(
                    onPressed: () => _openFilters(state),
                    icon: const Icon(Icons.tune_rounded,
                        color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          if (widget.showCompatibleToggle && state.hasVehicle) ...[
            const SizedBox(height: AppDimensions.spacing8),
            FilterChip(
              avatar: Icon(
                Icons.electric_car_rounded,
                size: 16,
                color: state.compatibleOnly
                    ? AppColors.textOnPrimary
                    : AppColors.accent,
              ),
              label: Text('Fits my ${state.vehicleName ?? 'car'}'),
              selected: state.compatibleOnly,
              showCheckmark: false,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface.withValues(alpha: 0.95),
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: state.compatibleOnly
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
              onSelected: (v) =>
                  context.read<StationsBloc>().add(CompatibleOnlyToggled(v)),
            ),
          ],
        ],
      ),
    );
  }
}
