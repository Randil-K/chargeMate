import 'package:flutter/material.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/features/station/domain/entities/station_filter.dart';

/// Modal sheet for choosing connector, speed, status & sort filters.
/// Returns the new [StationFilter] via `Navigator.pop`.
class FilterBottomSheet extends StatefulWidget {
  final StationFilter initial;
  final List<String> networks;

  const FilterBottomSheet({
    super.key,
    required this.initial,
    required this.networks,
  });

  static Future<StationFilter?> show(
    BuildContext context, {
    required StationFilter initial,
    required List<String> networks,
  }) =>
      showModalBottomSheet<StationFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXLarge)),
        ),
        builder: (_) => FilterBottomSheet(initial: initial, networks: networks),
      );

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late StationFilter _f = widget.initial;

  static const _connectors = [
    AppConstants.connectorCCS2,
    AppConstants.connectorCHAdeMO,
    AppConstants.connectorType2,
    AppConstants.connectorType1,
    AppConstants.connectorGBT,
  ];
  static const _speeds = <(double, String)>[
    (0, 'Any'),
    (22, '22 kW+'),
    (50, '50 kW+'),
    (100, '100 kW+'),
  ];

  Set<String> _toggle(Set<String> set, String v) {
    final copy = {...set};
    if (!copy.remove(v)) copy.add(v);
    return copy;
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(
            top: AppDimensions.spacing20, bottom: AppDimensions.spacing10),
        child: Text(title.toUpperCase(),
            style: AppTextStyles.overline
                .copyWith(color: AppColors.textSecondary)),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: AppDimensions.spacing10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Text('Filters', style: AppTextStyles.headingMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _f = StationFilter.none),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _section('Sort by'),
                SegmentedButton<StationSort>(
                  segments: const [
                    ButtonSegment(
                        value: StationSort.distance,
                        label: Text('Nearest'),
                        icon: Icon(Icons.near_me_outlined)),
                    ButtonSegment(
                        value: StationSort.power,
                        label: Text('Fastest'),
                        icon: Icon(Icons.bolt_outlined)),
                    ButtonSegment(
                        value: StationSort.rating,
                        label: Text('Top rated'),
                        icon: Icon(Icons.star_outline_rounded)),
                  ],
                  selected: {_f.sort},
                  onSelectionChanged: (v) =>
                      setState(() => _f = _f.copyWith(sort: v.first)),
                ),
                _section('Connector type'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _connectors)
                      FilterChip(
                        label: Text(c),
                        selected: _f.connectorTypes.contains(c),
                        onSelected: (_) => setState(() => _f = _f.copyWith(
                            connectorTypes: _toggle(_f.connectorTypes, c))),
                      ),
                  ],
                ),
                _section('Minimum charging speed'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _speeds)
                      ChoiceChip(
                        label: Text(e.$2),
                        selected: _f.minPowerKw == e.$1,
                        onSelected: (_) => setState(
                            () => _f = _f.copyWith(minPowerKw: e.$1)),
                      ),
                  ],
                ),
                _section('Network'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in widget.networks)
                      FilterChip(
                        label: Text(n),
                        selected: _f.networks.contains(n),
                        onSelected: (_) => setState(() => _f =
                            _f.copyWith(networks: _toggle(_f.networks, n))),
                      ),
                  ],
                ),
                _section('Availability'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Operational stations only'),
                  value: _f.onlyOperational,
                  onChanged: (v) =>
                      setState(() => _f = _f.copyWith(onlyOperational: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Has a free charger now'),
                  value: _f.onlyAvailableNow,
                  onChanged: (v) =>
                      setState(() => _f = _f.copyWith(onlyAvailableNow: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open 24 hours'),
                  value: _f.only24Hours,
                  onChanged: (v) =>
                      setState(() => _f = _f.copyWith(only24Hours: v)),
                ),
                const SizedBox(height: AppDimensions.spacing16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: CustomButton(
                text: 'Apply filters',
                onPressed: () => Navigator.pop(context, _f),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
