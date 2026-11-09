import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';

/// Centered spinner in brand colour.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
}

/// Skeleton placeholder list used while data loads.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerList({super.key, this.count = 5, this.itemHeight = 110});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
        itemCount: count,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDimensions.spacing12),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
        ),
      ),
    );
  }
}

/// Friendly message with an icon and an optional action.
class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.primary,
  });

  factory MessageView.error(String message, {VoidCallback? onRetry}) =>
      MessageView(
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        subtitle: message,
        actionLabel: onRetry != null ? 'Try again' : null,
        onAction: onRetry,
        color: AppColors.error,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppDimensions.iconHero, color: color),
            ),
            const SizedBox(height: AppDimensions.spacing20),
            Text(title,
                style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              CustomButton(
                text: actionLabel!,
                onPressed: onAction,
                width: 200,
                height: AppDimensions.buttonHeightMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
