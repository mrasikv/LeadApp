import 'package:equatable/equatable.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/project_type_model.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {
  final String companyId;

  const LoadProjectsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadProjectEvent extends ProjectEvent {
  final String projectId;

  const LoadProjectEvent(this.projectId);

  @override
  List<Object> get props => [projectId];
}

class WatchProjectsEvent extends ProjectEvent {
  final String companyId;

  const WatchProjectsEvent(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateProjectEvent extends ProjectEvent {
  final Project project;
  final ProjectType projectType;

  const CreateProjectEvent({
    required this.project,
    required this.projectType,
  });

  @override
  List<Object> get props => [project, projectType];
}

class UpdateProjectEvent extends ProjectEvent {
  final Project project;

  const UpdateProjectEvent(this.project);

  @override
  List<Object> get props => [project];
}

class DeleteProjectEvent extends ProjectEvent {
  final String projectId;

  const DeleteProjectEvent(this.projectId);

  @override
  List<Object> get props => [projectId];
}

class ToggleProjectActiveEvent extends ProjectEvent {
  final String projectId;
  final bool isActive;

  const ToggleProjectActiveEvent({
    required this.projectId,
    required this.isActive,
  });

  @override
  List<Object> get props => [projectId, isActive];
}

class UpdateProjectLeadCountsEvent extends ProjectEvent {
  final String projectId;

  const UpdateProjectLeadCountsEvent(this.projectId);

  @override
  List<Object> get props => [projectId];
}

class SelectProjectEvent extends ProjectEvent {
  final Project? project;

  const SelectProjectEvent(this.project);

  @override
  List<Object?> get props => [project];
}
