import 'package:flutter/material.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';

/// A premium gradient button with loading state and glow effect.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double? height;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return _buildOutlined();
    }
    return _buildFilled();
  }

  Widget _buildFilled() {
    final buttonGradient = gradient ?? AppColors.primaryGradient;

    return Container(
      width: width ?? double.infinity,
      height: height ?? AppDimensions.buttonHeightLarge,
      decoration: BoxDecoration(
        gradient: onPressed != null && !isLoading ? buttonGradient : null,
        color: onPressed == null || isLoading
            ? AppColors.surfaceVariant
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: AppColors.textOnPrimary,
                          size: AppDimensions.iconMedium,
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                      ],
                      Text(
                        text,
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlined() {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppDimensions.buttonHeightLarge,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: AppColors.primary,
                      size: AppDimensions.iconMedium,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
