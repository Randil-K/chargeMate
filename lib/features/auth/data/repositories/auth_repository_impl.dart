import 'package:dartz/dartz.dart';

import 'package:charge_mate/core/errors/exceptions.dart';
import 'package:charge_mate/core/errors/failures.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:charge_mate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:charge_mate/features/auth/data/models/user_model.dart';
import 'package:charge_mate/features/auth/domain/entities/user.dart';
import 'package:charge_mate/features/auth/domain/repositories/auth_repository.dart';

/// Coordinates remote auth calls with local session persistence and
/// converts data-layer exceptions into domain [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  const AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) =>
      _run(() async {
        final auth = await _remote.login(email, password);
        await _local.saveSession(auth);
        return auth.user;
      });

  @override
  Future<Either<Failure, User>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) =>
      _run(() async {
        final auth = await _remote.register(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
        );
        await _local.saveSession(auth);
        return auth.user;
      });

  @override
  Future<Either<Failure, Unit>> logout() => _run(() async {
        await _local.clearSession();
        return unit;
      });

  @override
  Future<Either<Failure, User?>> getCurrentUser() =>
      _run(() => _local.getCachedUser());

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) =>
      _run(() async {
        await _remote.requestPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, User>> updateProfile(User user) => _run(() async {
        final updated =
            await _remote.updateProfile(UserModel.fromEntity(user));
        await _local.cacheUser(updated);
        return updated;
      });

  /// Single place that maps exceptions → failures.
  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
