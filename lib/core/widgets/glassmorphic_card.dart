import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';

/// A premium glassmorphic card with blur, semi-transparent background,
/// and subtle border highlight.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final double? blurSigma;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDimensions.radiusLarge;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma ?? AppDimensions.glassBlurSigma,
            sigmaY: blurSigma ?? AppDimensions.glassBlurSigma,
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.glassBg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: AppColors.glassStroke,
                  width: AppDimensions.cardBorderWidth,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: padding ??
                  const EdgeInsets.all(AppDimensions.spacing16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
