import 'package:flutter/material.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/utils/distance_utils.dart';
import 'package:charge_mate/features/station/domain/entities/charging_station.dart';
import 'package:charge_mate/features/station/presentation/widgets/station_badges.dart';

/// List & map card summarizing an EV charging station with high glanceability.
class StationCard extends StatelessWidget {
  final ChargingStation station;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback? onFavourite;
  final Set<String> vehicleConnectors;
  final bool compact;

  const StationCard({
    super.key,
    required this.station,
    required this.onTap,
    this.isFavourite = false,
    this.onFavourite,
    this.vehicleConnectors = const {},
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = station;
    final compatible =
        vehicleConnectors.isEmpty ? null : s.supportsAny(vehicleConnectors);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: compatible == true
                  ? AppColors.statusOperational.withValues(alpha: 0.35)
                  : AppColors.border,
              width: compatible == true ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(tag: 'power-${s.id}', child: PowerBadge(s.maxPowerKw)),
                  const SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.network} · ${s.city}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacing8),
                        Row(
                          children: [
                            StatusBadge.station(s.status, compact: true),
                            const SizedBox(width: AppDimensions.spacing8),
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.explore,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              s.rating.toStringAsFixed(1),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onFavourite != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onFavourite,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(isFavourite),
                          color: isFavourite
                              ? AppColors.error
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing12),
              Wrap(
                spacing: AppDimensions.spacing6,
                runSpacing: AppDimensions.spacing6,
                children: [
                  for (final c in s.connectorTypes)
                    ConnectorChip(c, highlighted: vehicleConnectors.contains(c)),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: AppDimensions.spacing12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppDimensions.spacing10),
              ] else
                const SizedBox(height: AppDimensions.spacing10),
              Row(
                children: [
                  _meta(
                    Icons.near_me_rounded,
                    s.distanceKm != null ? DistanceUtils.format(s.distanceKm!) : '—',
                    AppColors.primary,
                  ),
                  _meta(
                    Icons.ev_station_rounded,
                    '${s.availableCount}/${s.points.length} free',
                    s.availableCount > 0 ? AppColors.statusOperational : AppColors.statusIssues,
                  ),
                  if (s.minPrice != null)
                    _meta(
                      Icons.payments_outlined,
                      'Rs ${s.minPrice!.round()}/kWh',
                      AppColors.textSecondary,
                    ),
                  const Spacer(),
                  if (compatible != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (compatible ? AppColors.statusOperational : AppColors.error)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            compatible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: compatible ? AppColors.statusOperational : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            compatible ? 'Compatible' : 'Incompatible',
                            style: AppTextStyles.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: compatible ? AppColors.statusOperational : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color iconColor) => Padding(
        padding: const EdgeInsets.only(right: AppDimensions.spacing12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: AppDimensions.spacing4),
            Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}
