import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:charge_mate/core/network/dio_client.dart';
import 'package:charge_mate/core/services/location_service.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:charge_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:charge_mate/features/auth/domain/repositories/auth_repository.dart';
import 'package:charge_mate/features/auth/domain/usecases/auth_usecases.dart';
import 'package:charge_mate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:charge_mate/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:charge_mate/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:charge_mate/features/explore/domain/repositories/explore_repository.dart';
import 'package:charge_mate/features/review/data/datasources/review_remote_datasource.dart';
import 'package:charge_mate/features/review/data/repositories/review_repository_impl.dart';
import 'package:charge_mate/features/review/domain/repositories/review_repository.dart';
import 'package:charge_mate/features/review/domain/usecases/review_usecases.dart';
import 'package:charge_mate/features/review/presentation/bloc/review_cubit.dart';
import 'package:charge_mate/features/session/presentation/bloc/charging_session_cubit.dart';
import 'package:charge_mate/features/station/data/datasources/station_datasources.dart';
import 'package:charge_mate/features/station/data/repositories/station_repository_impl.dart';
import 'package:charge_mate/features/station/domain/repositories/station_repository.dart';
import 'package:charge_mate/features/station/domain/usecases/station_usecases.dart';
import 'package:charge_mate/features/station/presentation/bloc/stations_bloc.dart';
import 'package:charge_mate/features/vehicle/data/repositories/vehicle_repository_impl.dart';
import 'package:charge_mate/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:charge_mate/features/vehicle/domain/usecases/vehicle_usecases.dart';
import 'package:charge_mate/features/vehicle/presentation/bloc/vehicle_bloc.dart';

final sl = GetIt.instance;

/// Set to `false` once the Spring Boot backend is running.
/// Only the two data-source bindings below change; nothing else does.
const bool useMockBackend = true;

Future<void> configureDependencies() async {
  // ── External ──────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(DioClient.new)
    ..registerLazySingleton(LocationService.new);

  // ── Auth ──────────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(() => useMockBackend
        ? MockAuthRemoteDataSource(sl())
        : ApiAuthRemoteDataSource(sl<DioClient>().dio))
    ..registerLazySingleton(() => AuthLocalDataSource(sl(), sl()))
    ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl(), sl()))
    ..registerFactory(() => AuthBloc(
          login: LoginUseCase(sl()),
          register: RegisterUseCase(sl()),
          logout: LogoutUseCase(sl()),
          getCurrentUser: GetCurrentUserUseCase(sl()),
          resetPassword: RequestPasswordResetUseCase(sl()),
          updateProfile: UpdateProfileUseCase(sl()),
        ));

  // ── Stations ──────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<StationRemoteDataSource>(() => useMockBackend
        ? MockStationRemoteDataSource()
        : ApiStationRemoteDataSource(sl<DioClient>().dio))
    ..registerLazySingleton(() => StationLocalDataSource(sl()))
    ..registerLazySingleton<StationRepository>(
        () => StationRepositoryImpl(sl(), sl()))
    ..registerFactory(() => StationsBloc(
          location: sl(),
          getNearby: GetNearbyStationsUseCase(sl()),
          getFavourites: GetFavouriteStationsUseCase(sl()),
          toggleFavourite: ToggleFavouriteStationUseCase(sl()),
        ));

  // ── Vehicles ──────────────────────────────────────────────────────
  sl
    ..registerLazySingleton<VehicleRepository>(
        () => VehicleRepositoryImpl(sl()))
    ..registerFactory(() => VehicleBloc(
          get: GetVehiclesUseCase(sl()),
          add: AddVehicleUseCase(sl()),
          update: UpdateVehicleUseCase(sl()),
          delete: DeleteVehicleUseCase(sl()),
          setPrimary: SetPrimaryVehicleUseCase(sl()),
          specs: GetVehicleSpecsUseCase(sl()),
        ));

  // ── Charge & Explore (Module 4) ───────────────────────────────────
  sl
    ..registerLazySingleton<ExploreRemoteDataSource>(() => useMockBackend
        ? MockExploreRemoteDataSource()
        : ApiExploreRemoteDataSource(sl<DioClient>().dio))
    ..registerLazySingleton<ExploreRepository>(
        () => ExploreRepositoryImpl(sl()));

  // ── Reviews & Community Reporting (Module 5) ──────────────────────
  sl
    ..registerLazySingleton<ReviewRemoteDataSource>(() => useMockBackend
        ? MockReviewRemoteDataSource()
        : ApiReviewRemoteDataSource(sl<DioClient>()))
    ..registerLazySingleton<ReviewRepository>(
        () => ReviewRepositoryImpl(sl()))
    ..registerFactory(() => ReviewCubit(
          getReviews: GetStationReviewsUseCase(sl()),
          submitReview: SubmitStationReviewUseCase(sl()),
        ))
    ..registerLazySingleton(ChargingSessionCubit.new);
}
