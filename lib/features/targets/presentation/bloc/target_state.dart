import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/target_model.dart';

abstract class TargetState extends Equatable {
  const TargetState();

  @override
  List<Object?> get props => [];
}

class TargetInitial extends TargetState {}

class TargetLoading extends TargetState {}

class TargetLoaded extends TargetState {
  final Target target;

  const TargetLoaded(this.target);

  @override
  List<Object> get props => [target];
}

class TargetsLoaded extends TargetState {
  final List<Target> targets;

  const TargetsLoaded(this.targets);

  @override
  List<Object> get props => [targets];
}

class TargetCreated extends TargetState {
  final Target target;

  const TargetCreated(this.target);

  @override
  List<Object> get props => [target];
}

class TargetUpdated extends TargetState {}

class TargetDeleted extends TargetState {}

class TargetProgressUpdated extends TargetState {}

class TargetError extends TargetState {
  final AppError error;

  const TargetError(this.error);

  @override
  List<Object> get props => [error];
}
