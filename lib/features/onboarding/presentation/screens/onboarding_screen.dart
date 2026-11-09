import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:charge_mate/app/theme/app_colors.dart';
import 'package:charge_mate/app/theme/app_dimensions.dart';
import 'package:charge_mate/app/theme/app_text_styles.dart';
import 'package:charge_mate/core/widgets/custom_button.dart';
import 'package:charge_mate/features/auth/presentation/widgets/auth_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.ev_station_rounded,
      color: AppColors.primary,
      title: 'Find chargers fast',
      body: 'See nearby stations on the map with live status, speeds and prices.',
    ),
    (
      icon: Icons.electric_car_rounded,
      color: AppColors.accent,
      title: 'Know it fits your EV',
      body: 'Register your car once and instantly see which connectors work.',
    ),
    (
      icon: Icons.explore_rounded,
      color: AppColors.secondary,
      title: 'Charge & explore',
      body: 'Discover cafés, shops and sights around your charging stop. Coming soon.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.color.withValues(alpha: 0.12),
                              boxShadow: [
                                BoxShadow(
                                    color: p.color.withValues(alpha: 0.3),
                                    blurRadius: 60),
                              ],
                            ),
                            child: Icon(p.icon, size: 96, color: p.color),
                          )
                              .animate(key: ValueKey(i))
                              .scale(
                                  begin: const Offset(0.7, 0.7),
                                  curve: Curves.easeOutBack)
                              .fadeIn(),
                          const SizedBox(height: 48),
                          Text(p.title,
                              style: AppTextStyles.displaySmall,
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text(
                            p.body,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.pagePaddingHorizontal),
                child: CustomButton(
                  text: last ? 'Get started' : 'Next',
                  onPressed: () => last
                      ? widget.onDone()
                      : _controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
