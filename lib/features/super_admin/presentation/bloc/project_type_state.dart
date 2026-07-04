import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/project_type_model.dart';

abstract class ProjectTypeState extends Equatable {
  const ProjectTypeState();

  @override
  List<Object?> get props => [];
}

class ProjectTypeInitial extends ProjectTypeState {}

class ProjectTypeLoading extends ProjectTypeState {}

class ProjectTypesLoaded extends ProjectTypeState {
  final List<ProjectType> projectTypes;

  const ProjectTypesLoaded(this.projectTypes);

  @override
  List<Object> get props => [projectTypes];
}

class ProjectTypeLoaded extends ProjectTypeState {
  final ProjectType projectType;

  const ProjectTypeLoaded(this.projectType);

  @override
  List<Object> get props => [projectType];
}

class ProjectTypeCreated extends ProjectTypeState {
  final ProjectType projectType;

  const ProjectTypeCreated(this.projectType);

  @override
  List<Object> get props => [projectType];
}

class ProjectTypeUpdated extends ProjectTypeState {}

class ProjectTypeDeleted extends ProjectTypeState {}

class ProjectTypeError extends ProjectTypeState {
  final AppError error;

  const ProjectTypeError(this.error);

  @override
  List<Object> get props => [error];
}
