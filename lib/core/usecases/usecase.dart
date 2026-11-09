import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:charge_mate/core/errors/failures.dart';

/// Base use case interface.
///
/// Every use case in the domain layer implements this contract.
/// [T] is the return type, [Params] is the input parameter type.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use when the use case requires no input parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
