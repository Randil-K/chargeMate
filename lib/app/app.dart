import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:charge_mate/app/router.dart';
import 'package:charge_mate/app/theme/app_theme.dart';
import 'package:charge_mate/core/constants/app_constants.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/session/presentation/bloc/charging_session_cubit.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'package:charge_mate/injection.dart';

class ChargeMateApp extends StatefulWidget {
  const ChargeMateApp({super.key});

  @override
  State<ChargeMateApp> createState() => _ChargeMateAppState();
}

class _ChargeMateAppState extends State<ChargeMateApp> {
  late final AuthBloc _auth = sl<AuthBloc>()..add(const AuthCheckRequested());
  late final StationsBloc _stations = sl<StationsBloc>();
  late final VehicleBloc _vehicles = sl<VehicleBloc>();
  late final ChargingSessionCubit _session = sl<ChargingSessionCubit>();
  late final GoRouter _router = buildRouter(
    authBloc: _auth,
    onboardingDone: () => sl<AuthLocalDataSource>().isOnboardingComplete,
    completeOnboarding: () => sl<AuthLocalDataSource>().setOnboardingComplete(),
  );

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    _stations.close();
    _vehicles.close();
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _auth),
        BlocProvider.value(value: _stations),
        BlocProvider.value(value: _vehicles),
        BlocProvider.value(value: _session),
      ],
      // Load user-scoped data whenever a session becomes authenticated.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) =>
            a.status != b.status && b.status == AuthStatus.authenticated,
        listener: (context, _) {
          _stations.add(const StationsRequested());
          _vehicles.add(const VehiclesRequested());
        },
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: _router,
        ),
      ),
    );
  }
}
