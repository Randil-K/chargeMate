import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/core/utils/validators.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/core/widgets/custom_text_field.dart';
import 'package:charge_mate/features/vehicle/domain/entities/vehicle.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

/// Add or edit a vehicle. Picking a catalog model auto-fills verified specs.
class AddVehicleScreen extends StatefulWidget {
  final String? editingId;
  const AddVehicleScreen({super.key, this.editingId});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  static const _allConnectors = [
    AppConstants.connectorCCS2,
    AppConstants.connectorCHAdeMO,
    AppConstants.connectorType2,
    AppConstants.connectorType1,
    AppConstants.connectorGBT,
  ];

  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _battery = TextEditingController();
  final _range = TextEditingController();
  final _maxAc = TextEditingController();
  final _maxDc = TextEditingController();

  String? _manufacturer;
  VehicleSpec? _spec;
  int _year = DateTime.now().year;
  final Map<String, double> _connectors = {}; // type -> max kW
  Vehicle? _editing;
  int _initialSaveCount = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<VehicleBloc>().state;
    _initialSaveCount = state.saveCount;
    if (widget.editingId != null) {
      final v = state.byId(widget.editingId!);
      if (v != null) {
        _editing = v;
        _manufacturer = v.manufacturer;
        _year = v.year;
        _nickname.text = v.nickname ?? '';
        _battery.text = '${v.batteryKwh}';
        _range.text = '${v.rangeKm}';
        _maxAc.text = '${v.maxAcKw}';
        _maxDc.text = '${v.maxDcKw}';
        for (final c in v.connectors) {
          _connectors[c.type] = c.maxKw;
        }
        for (final s in state.catalog) {
          if (s.specId == v.specId) _spec = s;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_nickname, _battery, _range, _maxAc, _maxDc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applySpec(VehicleSpec s) {
    setState(() {
      _spec = s;
      _year = _year.clamp(s.fromYear, s.toYear);
      _battery.text = '${s.batteryKwh}';
      _range.text = '${s.rangeKm}';
      _maxAc.text = '${s.maxAcKw}';
      _maxDc.text = '${s.maxDcKw}';
      _connectors
        ..clear()
        ..addEntries(s.connectors.map((c) => MapEntry(c.type, c.maxKw)));
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_manufacturer == null) return;
    final spec = _spec;
    final vehicle = Vehicle(
      id: _editing?.id ?? '',
      manufacturer: _manufacturer!,
      model: spec?.model ?? _editing?.model ?? 'Custom',
      year: _year,
      nickname: _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
      batteryKwh: double.parse(_battery.text),
      rangeKm: double.parse(_range.text).round(),
      maxAcKw: double.tryParse(_maxAc.text) ?? 0,
      maxDcKw: double.tryParse(_maxDc.text) ?? 0,
      connectors: [
        for (final e in _connectors.entries)
          VehicleConnector(type: e.key, maxKw: e.value),
      ],
      isPrimary: _editing?.isPrimary ?? false,
      specId: spec?.specId ?? _editing?.specId,
    );
    final bloc = context.read<VehicleBloc>();
    bloc.add(_editing != null ? VehicleUpdated(vehicle) : VehicleAdded(vehicle));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehicleBloc, VehicleState>(
      listenWhen: (a, b) => a.saveCount != b.saveCount || a.error != b.error,
      listener: (context, state) {
        if (state.saveCount > _initialSaveCount) {
          context.pop();
        } else if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final manufacturers =
            state.catalog.map((s) => s.manufacturer).toSet().toList()..sort();
        final models = state.catalog
            .where((s) => s.manufacturer == _manufacturer)
            .toList();

        return Scaffold(
          appBar: AppBar(
              title: Text(_editing != null ? 'Edit vehicle' : 'Add vehicle')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _manufacturer,
                  decoration: const InputDecoration(labelText: 'Manufacturer'),
                  dropdownColor: AppColors.surfaceVariant,
                  items: [
                    for (final m in manufacturers)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  validator: (v) => v == null ? 'Choose a manufacturer' : null,
                  onChanged: (v) => setState(() {
                    _manufacturer = v;
                    _spec = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<VehicleSpec>(
                  key: ValueKey(_manufacturer),
                  initialValue: _spec,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Model'),
                  dropdownColor: AppColors.surfaceVariant,
                  items: [
                    for (final s in models)
                      DropdownMenuItem(value: s, child: Text(s.model)),
                  ],
                  onChanged: _manufacturer == null
                      ? null
                      : (s) => s == null ? null : _applySpec(s),
                ),
                if (_spec != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text('Specs auto-filled from catalog',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accent)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration:
                      const InputDecoration(labelText: 'Manufacturing year'),
                  dropdownColor: AppColors.surfaceVariant,
                  items: [
                    for (var y = DateTime.now().year; y >= 2010; y--)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nickname (optional)',
                  controller: _nickname,
                  prefixIcon: Icons.edit_outlined,
                ),
                const SizedBox(height: 24),
                Text('Specifications', style: AppTextStyles.headingSmall),
                const SizedBox(height: 4),
                Text('You can override auto-filled values.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Battery (kWh)',
                        controller: _battery,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) =>
                            Validators.positiveNumber(v, 'battery'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Range (km)',
                        controller: _range,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) =>
                            Validators.positiveNumber(v, 'range'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Max AC (kW)',
                        controller: _maxAc,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Max DC (kW)',
                        controller: _maxDc,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Supported connectors', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _allConnectors)
                      FilterChip(
                        label: Text(c),
                        selected: _connectors.containsKey(c),
                        onSelected: (on) => setState(() {
                          if (on) {
                            _connectors[c] = c == AppConstants.connectorType2 ||
                                    c == AppConstants.connectorType1
                                ? (double.tryParse(_maxAc.text) ?? 7)
                                : (double.tryParse(_maxDc.text) ?? 50);
                          } else {
                            _connectors.remove(c);
                          }
                        }),
                      ),
                  ],
                ),
                if (_connectors.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Select at least one connector',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error)),
                  ),
                const SizedBox(height: AppDimensions.spacing32),
                CustomButton(
                  text: _editing != null ? 'Save changes' : 'Save vehicle',
                  onPressed: _connectors.isEmpty ? null : _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
