import 'package:dartz/dartz.dart';
import '../error/app_error.dart';

typedef ResultFuture<T> = Future<Either<AppError, T>>;
typedef ResultVoid = Future<Either<AppError, void>>;

abstract class UseCase<Type, Params> {
  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  ResultFuture<Type> call();
}

abstract class StreamUseCase<Type, Params> {
  Stream<Either<AppError, Type>> call(Params params);
}
