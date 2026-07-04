import 'package:equatable/equatable.dart';
import '../../../../core/models/project_type_model.dart';

abstract class ProjectTypeEvent extends Equatable {
  const ProjectTypeEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectTypesEvent extends ProjectTypeEvent {
  const LoadProjectTypesEvent();
}

class LoadProjectTypeEvent extends ProjectTypeEvent {
  final String projectTypeId;

  const LoadProjectTypeEvent(this.projectTypeId);

  @override
  List<Object> get props => [projectTypeId];
}

class WatchProjectTypesEvent extends ProjectTypeEvent {
  const WatchProjectTypesEvent();
}

class CreateProjectTypeEvent extends ProjectTypeEvent {
  final ProjectType projectType;

  const CreateProjectTypeEvent(this.projectType);

  @override
  List<Object> get props => [projectType];
}

class UpdateProjectTypeEvent extends ProjectTypeEvent {
  final ProjectType projectType;

  const UpdateProjectTypeEvent(this.projectType);

  @override
  List<Object> get props => [projectType];
}

class DeleteProjectTypeEvent extends ProjectTypeEvent {
  final String projectTypeId;

  const DeleteProjectTypeEvent(this.projectTypeId);

  @override
  List<Object> get props => [projectTypeId];
}

class ToggleProjectTypeActiveEvent extends ProjectTypeEvent {
  final String projectTypeId;
  final bool isActive;

  const ToggleProjectTypeActiveEvent({
    required this.projectTypeId,
    required this.isActive,
  });

  @override
  List<Object> get props => [projectTypeId, isActive];
}
