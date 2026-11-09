import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';

/// Glowing gradient logo mark used on splash and auth screens.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: size * 0.5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.bolt_rounded,
        color: AppColors.textOnPrimary,
        size: size * 0.62,
      ),
    );
  }
}

/// Dark background with two soft, slowly pulsing colour orbs.
class GlowBackground extends StatelessWidget {
  final Widget child;
  const GlowBackground({super.key, required this.child});

  Widget _orb(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.85, end: 1.15, duration: 4.seconds);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(top: -120, right: -100, child: _orb(AppColors.primary, 340)),
          Positioned(
              bottom: -140, left: -120, child: _orb(AppColors.secondary, 380)),
          child,
        ],
      ),
    );
  }
}

/// Logo + title + subtitle block at the top of auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogo;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          const AppLogo(size: 56)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack),
          const SizedBox(height: AppDimensions.spacing24),
        ],
        Text(title, style: AppTextStyles.displaySmall)
            .animate()
            .fadeIn(delay: 100.ms)
            .slideX(begin: -0.1),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          subtitle,
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
      ],
    );
  }
}

/// Inline error banner for form-level errors.
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: AppDimensions.iconMedium),
          const SizedBox(width: AppDimensions.spacing8),
          Expanded(
            child: Text(message,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    ).animate().shakeX(hz: 4, amount: 4, duration: 400.ms);
  }
}
