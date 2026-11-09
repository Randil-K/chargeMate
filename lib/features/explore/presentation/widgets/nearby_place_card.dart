import 'package:flutter/material.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/utils/external_launcher.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';

IconData placeCategoryIcon(PlaceCategory c) => switch (c) {
      PlaceCategory.all => Icons.explore_rounded,
      PlaceCategory.foodBeverage => Icons.local_cafe_rounded,
      PlaceCategory.shopping => Icons.shopping_bag_rounded,
      PlaceCategory.entertainment => Icons.movie_filter_rounded,
      PlaceCategory.tourism => Icons.account_balance_rounded,
    };

Color placeCategoryColor(PlaceCategory c) => switch (c) {
      PlaceCategory.all => AppColors.primary,
      PlaceCategory.foodBeverage => AppColors.explore,
      PlaceCategory.shopping => AppColors.primary,
      PlaceCategory.entertainment => AppColors.secondary,
      PlaceCategory.tourism => AppColors.statusOperational,
    };

/// Card displaying a nearby place with time-budget compatibility,
/// walking distance, and 1-tap walking navigation.
class NearbyPlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final int chargingMinutes;

  const NearbyPlaceCard({
    super.key,
    required this.place,
    required this.chargingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final fits = place.fitsInTimeBudget(chargingMinutes);
    final catColor = placeCategoryColor(place.category);
    final fitColor = fits ? AppColors.statusOperational : AppColors.explore;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: fits
              ? AppColors.statusOperational.withValues(alpha: 0.35)
              : AppColors.border,
          width: fits ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: catColor.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  placeCategoryIcon(place.category),
                  color: catColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.subCategory} · ${place.priceLevel} · ${place.openingHours}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.explore.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.explore),
                    const SizedBox(width: 3),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.exploreLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing10),
          Text(
            place.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing10),
          // Time-budget & walking breakdown bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: fitColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: fitColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  fits ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 16,
                  color: fitColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fits
                        ? 'Fits your ${chargingMinutes}m charge (~${place.totalRoundTripMinutes}m round-trip)'
                        : 'Needs ~${place.totalRoundTripMinutes}m total (walk + visit)',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: fitColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in place.tags)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.spacing10),
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${place.walkingMinutes} min walk (${place.formattedDistance})',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textSecondary,
                ),
                onPressed: () async {
                  if (!await ExternalLauncher.call(place.phone) &&
                      context.mounted) {
                    ExternalLauncher.showFailure(context);
                  }
                },
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Call'),
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  if (!await ExternalLauncher.walkTo(
                          place.latitude, place.longitude) &&
                      context.mounted) {
                    ExternalLauncher.showFailure(context);
                  }
                },
                icon: const Icon(Icons.directions_walk_rounded, size: 16),
                label: const Text('Walk'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
