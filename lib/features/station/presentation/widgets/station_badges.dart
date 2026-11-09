import 'package:flutter/material.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';

Color stationStatusColor(StationStatus s) => switch (s) {
      StationStatus.operational => AppColors.statusOperational,
      StationStatus.issuesReported => AppColors.statusIssues,
      StationStatus.offline => AppColors.statusOffline,
      StationStatus.unknown => AppColors.statusUnknown,
    };

IconData stationStatusIcon(StationStatus s) => switch (s) {
      StationStatus.operational => Icons.check_circle_rounded,
      StationStatus.issuesReported => Icons.warning_amber_rounded,
      StationStatus.offline => Icons.cancel_rounded,
      StationStatus.unknown => Icons.help_outline_rounded,
    };

Color pointStatusColor(PointStatus s) => switch (s) {
      PointStatus.available => AppColors.statusOperational,
      PointStatus.inUse => AppColors.statusIssues,
      PointStatus.outOfService => AppColors.statusOffline,
      PointStatus.unknown => AppColors.statusUnknown,
    };

IconData pointStatusIcon(PointStatus s) => switch (s) {
      PointStatus.available => Icons.bolt_rounded,
      PointStatus.inUse => Icons.access_time_filled_rounded,
      PointStatus.outOfService => Icons.block_rounded,
      PointStatus.unknown => Icons.help_outline_rounded,
    };

String formatKw(double kw) =>
    kw == kw.roundToDouble() ? '${kw.toInt()} kW' : '${kw.toStringAsFixed(1)} kW';

/// Accessible status badge featuring dual encoding: color + icon + text.
/// Complies with WCAG guidelines so colorblind users are never confused.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  factory StatusBadge.station(StationStatus s, {bool compact = false}) =>
      StatusBadge(
        label: s.label,
        color: stationStatusColor(s),
        icon: stationStatusIcon(s),
        compact: compact,
      );

  factory StatusBadge.point(PointStatus p, {bool compact = false}) =>
      StatusBadge(
        label: p.label,
        color: pointStatusColor(p),
        icon: pointStatusIcon(p),
        compact: compact,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimensions.spacing8 : AppDimensions.spacing10,
        vertical: compact ? AppDimensions.spacing2 : AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: color,
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: AppDimensions.spacing6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill showing a connector type; highlighted with neon glow when matching vehicle.
class ConnectorChip extends StatelessWidget {
  final String type;
  final bool highlighted;

  const ConnectorChip(this.type, {super.key, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing10,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.power_rounded, size: 13, color: color),
          const SizedBox(width: AppDimensions.spacing4),
          Text(
            type,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large glanceable power badge showing peak kW, color-coded by speed tier.
class PowerBadge extends StatelessWidget {
  final double kw;
  final double size;
  const PowerBadge(this.kw, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.chargingSpeedColor(kw);
    final isUltra = kw >= 100;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: isUltra ? 0.6 : 0.4),
          width: isUltra ? 1.5 : 1,
        ),
        boxShadow: isUltra
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUltra ? Icons.bolt_rounded : Icons.flash_on_rounded,
            color: color,
            size: size * 0.36,
          ),
          Text(
            kw.round().toString(),
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          Text(
            'kW',
            style: AppTextStyles.overline.copyWith(
              color: color.withValues(alpha: 0.9),
              height: 1.1,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
