import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/main_shell.dart';
import 'package:charge_mate/app/routes.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:charge_mate/features/auth/presentation/screens/login_screen.dart';
import 'package:charge_mate/features/auth/presentation/screens/register_screen.dart';
import 'package:charge_mate/features/explore/presentation/screens/charge_and_explore_screen.dart';
import 'package:charge_mate/features/home/presentation/screens/home_screen.dart';
import 'package:charge_mate/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:charge_mate/features/profile/presentation/screens/profile_screens.dart';
import 'package:charge_mate/features/splash/presentation/screens/splash_screen.dart';
import 'package:charge_mate/features/station/presentation/screens/station_detail_screen.dart';
import 'package:charge_mate/features/station/presentation/screens/station_list_screen.dart';
import 'package:charge_mate/features/station/presentation/screens/station_map_screen.dart';
import 'package:charge_mate/features/vehicle/presentation/screens/add_vehicle_screen.dart';
import 'package:charge_mate/features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import 'package:charge_mate/features/vehicle/presentation/screens/vehicle_list_screen.dart';

/// Re-runs the router redirect whenever a stream emits.
class _Refresh extends ChangeNotifier {
  _Refresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter({
  required AuthBloc authBloc,
  required bool Function() onboardingDone,
  required Future<void> Function() completeOnboarding,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _Refresh(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      final signedIn = status == AuthStatus.authenticated;
      if (!signedIn) {
        if (!onboardingDone()) {
          return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
        }
        return AppRoutes.public.contains(loc) && loc != AppRoutes.splash
            ? null
            : AppRoutes.login;
      }
      // Signed in: keep out of auth screens.
      if (AppRoutes.public.contains(loc)) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => OnboardingScreen(onDone: () async {
          await completeOnboarding();
          if (context.mounted) context.go(AppRoutes.login);
        }),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.map,
                builder: (_, _) => const StationMapScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.vehicles,
              builder: (_, _) => const VehicleListScreen(),
              routes: [
                GoRoute(
                    path: 'add', builder: (_, _) => const AddVehicleScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, s) =>
                      VehicleDetailScreen(vehicleId: s.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, s) =>
                          AddVehicleScreen(editingId: s.pathParameters['id']),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(
                    path: 'edit',
                    builder: (_, _) => const EditProfileScreen()),
              ],
            ),
          ]),
        ],
      ),

      GoRoute(
        path: AppRoutes.stations,
        builder: (_, _) => const StationListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                StationDetailScreen(stationId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'explore',
                builder: (_, s) => ChargeAndExploreScreen(
                  stationId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
          path: AppRoutes.favourites,
          builder: (_, _) => const FavouritesScreen()),
    ],
  );
}
