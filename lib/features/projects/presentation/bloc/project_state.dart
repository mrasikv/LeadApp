import 'package:equatable/equatable.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/models/project_model.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  final List<Project> projects;
  final Project? selectedProject;

  const ProjectsLoaded(this.projects, {this.selectedProject});

  @override
  List<Object?> get props => [projects, selectedProject];
}

class ProjectLoaded extends ProjectState {
  final Project project;

  const ProjectLoaded(this.project);

  @override
  List<Object> get props => [project];
}

class ProjectCreated extends ProjectState {
  final Project project;

  const ProjectCreated(this.project);

  @override
  List<Object> get props => [project];
}

class ProjectUpdated extends ProjectState {}

class ProjectDeleted extends ProjectState {}

class ProjectError extends ProjectState {
  final AppError error;

  const ProjectError(this.error);

  @override
  List<Object> get props => [error];
}
