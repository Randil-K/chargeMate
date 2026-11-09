import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:charge_mate/features/explore/domain/entities/nearby_place.dart';
import 'package:charge_mate/features/explore/domain/repositories/explore_repository.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreRemoteDataSource _remote;
  const ExploreRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<NearbyPlace>>> getPlacesNearStation({
    required String stationId,
    required double stationLat,
    required double stationLng,
  }) async {
    try {
      final places = await _remote.fetchPlacesNearStation(
        stationId: stationId,
        stationLat: stationLat,
        stationLng: stationLng,
      );
      return Right(places);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
