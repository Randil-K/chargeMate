import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/features/auth/presentation/widgets/auth_widgets.dart';

/// Shown while the session is restored. The router redirects away from it
/// once [AuthBloc] leaves `AuthStatus.unknown`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 96)
                  .animate()
                  .scale(
                      begin: const Offset(0.4, 0.4),
                      duration: 700.ms,
                      curve: Curves.easeOutBack)
                  .fadeIn()
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.white54),
              const SizedBox(height: 24),
              Text(AppConstants.appName, style: AppTextStyles.displayMedium)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                'Charge. Explore. Enjoy.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}
